import os
import re
from config.gemini_config import model

KB_DIR = r"d:\USER FILES\Documents\neuro_guard\backend\data\knowledge_base"

def retrieve_chunks(query, top_n=3):
    """
    Reads files from the KB directory, splits them into paragraphs,
    ranks them by keyword overlap, and returns the top matching paragraphs.
    """
    if not os.path.exists(KB_DIR):
        return []

    # Clean the query and extract words
    query_words = [w.lower() for w in re.findall(r'\w+', query) if len(w) > 2]
    
    chunks = []
    
    # Read files
    for filename in os.listdir(KB_DIR):
        if not filename.endswith(".txt"):
            continue
        file_path = os.path.join(KB_DIR, filename)
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        # Split by empty lines to get paragraphs
        paragraphs = [p.strip() for p in content.split("\n\n") if p.strip()]
        
        for para in paragraphs:
            score = 0
            para_lower = para.lower()
            
            # Simple TF-IDF term overlap scoring
            for word in query_words:
                if word in para_lower:
                    score += para_lower.count(word)
            
            # Capture file reference info
            source = filename.replace(".txt", "").replace("_", " ").title()
            chunks.append({
                "text": para,
                "score": score,
                "source": source
            })

    # Sort by score descending
    chunks.sort(key=lambda x: x["score"], reverse=True)
    
    # Filter out chunks with 0 match score if we have any matching ones
    matched_chunks = [c for c in chunks if c["score"] > 0]
    if not matched_chunks:
        # Fallback to returning the first few general chunks
        return chunks[:top_n]
        
    return matched_chunks[:top_n]

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
