from flask import Flask, request, jsonify
from flask_cors import CORS
import sys
import io
import queue
import uuid
import logging
from threading import Timer
import time

# Setup logging
logging.basicConfig(level=logging.DEBUG)

app = Flask(__name__)
CORS(app)

# Store interactive sessions and their last active timestamps
interactive_sessions = {}
session_last_active = {}

# Session cleanup interval (in seconds)
SESSION_TIMEOUT = 600  # 10 minutes

def cleanup_sessions():
    """
    Periodically remove inactive sessions.
    """
    now = time.time()
    sessions_to_delete = [
        session_id for session_id, last_active in session_last_active.items()
        if now - last_active > SESSION_TIMEOUT
    ]
    for session_id in sessions_to_delete:
        del interactive_sessions[session_id]
        del session_last_active[session_id]
        logging.debug(f"Deleted inactive session: {session_id}")
    # Schedule the next cleanup
    Timer(SESSION_TIMEOUT, cleanup_sessions).start()

# Start the first cleanup
cleanup_sessions()

@app.route('/execute', methods=['POST'])
def execute_code():
    try:
        data = request.get_json()
        code = data.get("code", "")
        session_id = data.get("session_id", "")
        user_input = data.get("user_input", None)

        if not code.strip():
            return jsonify({
                "result": None,
                "error": "No code provided.",
                "session_id": None
            }), 400

        # Create a new session if not provided
        if not session_id:
            session_id = str(uuid.uuid4())

        # Update session activity
        session_last_active[session_id] = time.time()

        # Initialize session if not already done
        if session_id not in interactive_sessions:
            interactive_sessions[session_id] = queue.Queue()
        if user_input:
            interactive_sessions[session_id].put(user_input)

        # Redirect stdout to capture output
        output = io.StringIO()
        sys.stdout = output

        # Fake input function
        def fake_input(prompt=""):
            logging.debug(f"Prompt: {prompt}")
            if not interactive_sessions[session_id].empty():
                input_value = interactive_sessions[session_id].get()
                logging.debug(f"Returning input from queue: {input_value}")
                return input_value
            raise ValueError("No input provided.")

        # Temporarily replace input with fake_input
        original_input = __builtins__.input
        __builtins__.input = fake_input

        # Execute the code
        try:
            exec(code)
        except Exception as exec_error:
            sys.stdout = sys.__stdout__
            return jsonify({
                "result": None,
                "error": f"Execution Error: {str(exec_error)}",
                "session_id": session_id
            })

        # Reset input function and stdout
        __builtins__.input = original_input
        sys.stdout = sys.__stdout__
        result = output.getvalue()

        return jsonify({
            "result": result if result else "No Output",
            "session_id": session_id,
            "error": None
        })

    except Exception as e:
        sys.stdout = sys.__stdout__
        return jsonify({
            "result": None,
            "error": f"Server Error: {str(e)}",
            "session_id": None
        }), 500


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5001)
