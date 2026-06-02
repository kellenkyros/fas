import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader, Settings
from llama_index.core.node_parser import TokenTextSplitter
from llama_index.llms.ollama import Ollama
from llama_index.embeddings.ollama import OllamaEmbedding
# ➕ Import the Memory module
from llama_index.core.memory import ChatMemoryBuffer

app = FastAPI(title="FAS Codebase RAG API")

print("🤖 Connecting to host Ollama models...")
Settings.llm = Ollama(base_url="http://host.docker.internal:11434", model="qwen2.5-coder:1.5b", request_timeout=60.0)
Settings.embed_model = OllamaEmbedding(base_url="http://host.docker.internal:11434", model_name="nomic-embed-text")

chat_engine = None

@app.on_event("startup")
def initialize_rag():
    global chat_engine
    PROJECT_ROOT_DIR = "/app/fas" 
    
    code_splitter = TokenTextSplitter(
        chunk_size=600, chunk_overlap=100, separator="\n",
        backup_separators=["class ", "def ", "function ", "const ", "  "]
    )
    
    reader = SimpleDirectoryReader(
        input_dir=PROJECT_ROOT_DIR, recursive=True,
        required_exts=[".rb", ".js", ".jsx", ".ts", ".tsx"], exclude_hidden=True,
        exclude=["**/node_modules/**", "**/dist/**", "**/.git/**", "**/rag/**", "**/log/**", "**/tmp/**"]
    )
    documents = reader.load_data()
    nodes = code_splitter.get_nodes_from_documents(documents)
    index = VectorStoreIndex(nodes)
    
    # ➕ Define a memory buffer (token_limit locks how much history it holds)
    # 2048 tokens is usually perfect for keeping 5-10 turns of code context alive
    memory = ChatMemoryBuffer.from_defaults(token_limit=2048)
    
    # 🔄 Pass the memory buffer directly into the chat engine
    chat_engine = index.as_chat_engine(
        chat_mode="condense_plus_context",
        memory=memory,  # <-- Memory linked here
        similarity_top_k=5,
        system_prompt="You are an expert engineer debugging the FAS modular monolith application."
    )
    print("🔥 RAG API Server with Conversation Memory Ready!")

class ChatRequest(BaseModel):
    message: str

@app.post("/chat")
def chat_endpoint(request: ChatRequest):
    global chat_engine
    if not chat_engine:
        raise HTTPException(status_code=503, detail="RAG Engine is initializing")
    try:
        # The chat engine automatically looks at the memory buffer now
        response = chat_engine.chat(request.message)
        return {"response": str(response)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
