# Fullstack Web Development: FastAPI (Backend) & React (Frontend) Project Setup

This documentation covers how to scaffold a modern web development project using **FastAPI** (Python) for the backend and **React (with TypeScript & Vite)** for the frontend. It summarizes all the initial steps you’ve completed, serving as a future reference for similar projects.

## Directory Structure
```
webdev/
├── backend/   # FastAPI backend server (Python)
└── frontend/  # React frontend app (TypeScript + Vite)
```

---

## 1. Backend: FastAPI + SQLite

### Steps taken
1. **Created the backend folder:**
    ```bash
    mkdir webdev/backend
    ```

2. **Set up a Python virtual environment:**
    ```bash
    cd webdev/backend
    python -m venv venv
    # On Windows, activate:
    venv\Scripts\activate
    # (On Mac/Linux: source venv/bin/activate)
    ```

3. **Installed backend dependencies:**
    ```bash
    pip install fastapi uvicorn[standard] sqlalchemy aiosqlite pydantic
    pip freeze > requirements.txt
    ```

   - `fastapi`: Web framework
   - `uvicorn`: ASGI server to serve FastAPI
   - `sqlalchemy`: Database toolkit
   - `aiosqlite`: Async SQLite3 driver
   - `pydantic`: Data validation

---

## 2. Frontend: React + TypeScript (with Vite)

### Steps taken
1. **Created the frontend folder:**
    ```bash
    mkdir webdev/frontend
    ```

2. **Initialized a React + TypeScript project using Vite:**
    ```bash
    # Run from within the webdev folder:
    npm create vite@latest frontend -- --template react-ts
    # Follow the Vite CLI prompts and use the default project name (frontend) or as you wish.
    ```

3. **Installed frontend dependencies:**
    ```bash
    cd frontend
    npm install
    ```

4. **Started the React dev server:**
    ```bash
    npm run dev
    # Visit the local address shown (e.g., http://localhost:5173 )
    ```

---

## Tips for Next Steps
- You now have a ready-to-use backend and frontend folder; next, you can start building APIs (FastAPI) and connect & consume them from your frontend (React).
- It's good practice to version control both (`git init` if needed).
- For future scaling, you can further organize backend folders into `routers/`, `models/`, etc.
- Remember to keep backend and frontend running in their own terminals during development.

---

For any new project, just repeat these steps to get started!
