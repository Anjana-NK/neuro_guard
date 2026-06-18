import os
import re
import json
import math
import google.generativeai as genai
from config.gemini_config import model

KB_DIR = r"d:\USER FILES\Documents\neuro_guard\backend\data\knowledge_base"
CACHE_FILE = r"d:\USER FILES\Documents\neuro_guard\backend\data\kb_vector_cache.json"

def cosine_similarity(v1, v2):
    dot_prod = sum(a * b for a, b in zip(v1, v2))
    mag1 = math.sqrt(sum(a * a for a in v1))
    mag2 = math.sqrt(sum(b * b for b in v2))
    if mag1 == 0 or mag2 == 0:
        return 0
    return dot_prod / (mag1 * mag2)

def get_kb_last_modified():
    timestamps = []
    if os.path.exists(KB_DIR):
        for filename in os.listdir(KB_DIR):
            if filename.endswith(".txt"):
                path = os.path.join(KB_DIR, filename)
                timestamps.append(os.path.getmtime(path))
    return max(timestamps) if timestamps else 0

def rebuild_vector_cache():
    if not os.path.exists(KB_DIR):
        return []
    
    chunks = []
    for filename in os.listdir(KB_DIR):
        if not filename.endswith(".txt"):
            continue
        file_path = os.path.join(KB_DIR, filename)
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        paragraphs = [p.strip() for p in content.split("\n\n") if p.strip()]
        
        for para in paragraphs:
            source = filename.replace(".txt", "").replace("_", " ").title()
            chunks.append({
                "text": para,
                "source": source
            })
            
    if chunks:
        try:
            texts = [c["text"] for c in chunks]
            result = genai.embed_content(
                model="models/text-embedding-004",
                content=texts,
                task_type="retrieval_document"
            )
            embeddings = result.get('embedding', [])
            for idx, emb in enumerate(embeddings):
                chunks[idx]["vector"] = emb
        except Exception as e:
            print(f"Failed to generate batch embeddings: {e}")
            for c in chunks:
                try:
                    res = genai.embed_content(
                        model="models/text-embedding-004",
                        content=c["text"],
                        task_type="retrieval_document"
                    )
                    c["vector"] = res.get('embedding', [])
                except Exception:
                    c["vector"] = []
                    
    os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(chunks, f, indent=2)
        
    return chunks

def load_kb_chunks():
    rebuild = False
    if not os.path.exists(CACHE_FILE):
        rebuild = True
    else:
        try:
            cache_time = os.path.getmtime(CACHE_FILE)
            if get_kb_last_modified() > cache_time:
                rebuild = True
        except Exception:
            rebuild = True
            
    if rebuild:
        return rebuild_vector_cache()
        
    try:
        with open(CACHE_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return rebuild_vector_cache()

def retrieve_chunks(query, top_n=3):
    chunks = load_kb_chunks()
    if not chunks:
        return []
        
    try:
        res = genai.embed_content(
            model="models/text-embedding-004",
            content=query,
            task_type="retrieval_query"
        )
        query_vector = res.get('embedding', [])
    except Exception as e:
        print(f"Failed to generate query embedding: {e}")
        return chunks[:top_n]
        
    if not query_vector:
        return chunks[:top_n]
        
    scored_chunks = []
    for c in chunks:
        vector = c.get("vector")
        if not vector:
            score = 0
        else:
            score = cosine_similarity(query_vector, vector)
            
        scored_chunks.append({
            "text": c["text"],
            "score": score,
            "source": c["source"]
        })
        
    scored_chunks.sort(key=lambda x: x["score"], reverse=True)
    return scored_chunks[:top_n]

def query_rag_knowledge_base(query, profile=None):
    """
    Retrieves context matching the query and builds a prompt for Gemini
    to generate a retrieval-augmented answer.
    """
    chunks = retrieve_chunks(query)
    
    context_str = ""
    sources = []
    for c in chunks:
        context_str += f"--- Source: {c['source']} ---\n{c['text']}\n\n"
        if c['source'] not in sources:
            sources.append(c['source'])

    profile_context = ""
    if profile:
        profile_context = f"The user is: {profile.get('name', 'User')}, Role: {profile.get('role', 'I Need Support')}, State: {profile.get('state', 'Kerala')}."

    prompt = f"""
You are the Neuro Guard Knowledge Base Assistant.
You answer user questions using retrieval-augmented context.

User Profile Context:
{profile_context}

Retrieved Knowledge Base Chunks:
{context_str}

User Question:
{query}

Instructions:
1. Provide a detailed, helpful, and concise answer based primary on the provided chunks.
2. If the context does not answer the question directly, use your general intelligence to provide safe advice, but clearly state that it is general advice outside the official database.
3. Keep the response to under 200 words.
4. List the sources utilized: {', '.join(sources) if sources else 'General Support Database'}.
"""
    try:
        response = model.generate_content(prompt)
        return {
            "answer": response.text,
            "sources": sources
        }
    except Exception as e:
        return {
            "answer": f"Error generating answer: {str(e)}",
            "sources": []
        }
