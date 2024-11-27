from flask import Flask, request, jsonify
from flask_cors import CORS  # Import CORS
import sys
import io
import queue
import uuid
import logging

# Setup logging for debugging
logging.basicConfig(level=logging.DEBUG)

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Store user input requests and responses in a dictionary to handle interactive sessions
interactive_sessions = {}

@app.route('/execute', methods=['POST'])
def execute_code():
    try:
        data = request.get_json()
        code = data.get("code", "")
        session_id = data.get("session_id", "")  # Track user sessions
        user_input = data.get("user_input", None)  # Get any user input (if any)

        # Create a new session if not provided
        if not session_id:
            session_id = str(uuid.uuid4())

        # Manage interactive sessions
        if session_id not in interactive_sessions:
            interactive_sessions[session_id] = queue.Queue()
        if user_input:
            interactive_sessions[session_id].put(user_input)

        # Redirect stdout to capture output
        output = io.StringIO()
        sys.stdout = output

        # Replace the built-in input() with our interactive input handler
        def fake_input(prompt=""):
            logging.debug(f"Prompt: {prompt}")
            if not interactive_sessions[session_id].empty():
                input_value = interactive_sessions[session_id].get()
                logging.debug(f"Returning input from queue: {input_value}")
                return input_value
            logging.debug("No input available, returning default value.")
            return "default_input"  # Default value if no input provided

        # Temporarily replace input with fake_input
        original_input = __builtins__.input
        __builtins__.input = fake_input

        # Execute the code
        try:
            exec(code)
        except Exception as exec_error:
            sys.stdout = sys.__stdout__  # Reset stdout
            return jsonify({
                "result": None,
                "error": f"Execution Error: {str(exec_error)}",
                "session_id": session_id
            })

        # Reset input function and stdout
        __builtins__.input = original_input
        sys.stdout = sys.__stdout__
        result = output.getvalue()

        # Ensure result is valid
        return jsonify({
            "result": result if result else "No Output",
            "session_id": session_id,
            "error": None
        })

    except Exception as e:
        sys.stdout = sys.__stdout__  # Reset stdout
        return jsonify({
            "result": None,
            "error": f"Server Error: {str(e)}",
            "session_id": None
        })


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5001)
