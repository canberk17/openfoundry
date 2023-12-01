from flask import Flask, request, jsonify
from openai import OpenAI
import os
import subprocess
import re
from dotenv import load_dotenv
from flask_cors import CORS
import shutil
from datetime import datetime
from flask_socketio import SocketIO


# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)
CORS(app) 
socketio = SocketIO(app, cors_allowed_origins='*')

client = OpenAI(api_key=f"{os.environ.get('OPENAI_TOKEN')}")


def emit_log(message):
    print(f"Emitting: {message}")  # Debug print
    socketio.emit('log', {'data': message})



def extract_contract_name(source_code):
    match = re.search(r'contract (\w+)\s*{', source_code)
    if match:
        return match.group(1)
    else:
        return f"Contract_{datetime.now().strftime('%Y%m%d%H%M%S')}"
    

def run_forge_build():
    result = subprocess.run(["forge", "build"], capture_output=True, text=True)
    return result.stdout + result.stderr

def run_forge_test():
    result = subprocess.run(["forge", "test"], capture_output=True, text=True)
    return result.stdout + result.stderr

def get_directory_listing():
    result = subprocess.run(["ls", "-R"], capture_output=True, text=True)
    return result.stdout

def ask_openai(messages):
    response = client.chat.completions.create(
        model="gpt-4-1106-preview",
        messages=messages,
        temperature=0.2,
        top_p=.1,
        seed=32526,
        max_tokens=1000
    )
    return response.choices[0].message.content

def fix_import_paths(source_code, error_message):
    local_files = get_directory_listing()

    response = ask_openai([
        {
            "role": 'system',
            "content": 'You are an AI assistant skilled in Solidity development. Please review the provided Solidity source code and update any import paths to the correct locations within the project structure, and only return the correct solidity code in your answer.'
        },
        {
            "role": "user",
            "content":  f"Error Message: {error_message}\nLocal Files:\n{local_files}\nSource Code:\n{source_code}\n Please update any incorrect import paths and only return the correct solidity code in your answer."
        }
    ])
    updated_code = response

    # Assuming the source_code is a file path
    write_to_file(source_code, updated_code)

    write_to_file(source_code_path, updated_code)
    emit_log(f"Updated import paths in {source_code_path}")

def clean_test_code(test_code):
    # Use regular expressions to find and remove ```solidity and ``` occurrences
    cleaned_code = re.sub(r'```(solidity)?', '', test_code).strip()
    return cleaned_code

def write_to_file(file_path, content):
    with open(file_path, 'w') as file:
        file.write(content)
    emit_log(f"Content written to {file_path}")


def move_files(source_dir, destination_dir, file_extension):
    try:
        if not os.path.exists(destination_dir):
            os.makedirs(destination_dir)

        for file_name in os.listdir(source_dir):
            if file_name.endswith(file_extension):
                shutil.move(os.path.join(source_dir, file_name), os.path.join(destination_dir, file_name))
                emit_log(f"Moved {file_name} to {destination_dir}")
    except Exception as e:
        emit_log(f"Error occurred while moving files: {e}")
def clear_directory_contents(dir_path):
    try:
        for file_name in os.listdir(dir_path):
            file_path = os.path.join(dir_path, file_name)
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
        emit_log(f"Cleared contents of {dir_path}")
    except Exception as e:
        emit_log(f"Error occurred while clearing directory contents: {e}")

def fix_test_code(error_message, test_code):
    fixed_code = ask_openai([
        {
            "role": 'system',
            "content": 'You are an expert in Solidity and debugging Solidity code. Please fix the provided Solidity test script based on the error message. Your answer can only return the Solidity code.'
        },
        {
            "role": "user",
            "content": f"Error Message: {error_message}\nTest Code:\n{test_code}\nPlease fix the errors in this Solidity test script and return only the corrected code."
        }
    ])
    return fixed_code
def analyze_source_vulnerability(forge_test_results, question, solidity_test_code, solidity_source_code):
    prompt = {
        "role": 'system',
        "content": 'You are an AI assistant skilled in Solidity. Analyze the provided test results along with the Solidity source and test code. Explain why the tests failed, indicating potential vulnerabilities or logic issues in the source code.'
    }

    user_input = {
        "role": "user",
        "content": f"Test Results: {forge_test_results}\nQuestion: {question}\nSolidity Test Code: {solidity_test_code}\nSolidity Source Code: {solidity_source_code}\nPlease analyze this information and provide a detailed response."
    }

    response = ask_openai([prompt, user_input])
    return response

@app.route('/analyze', methods=['POST'])
def analyze():
    emit_log("Analyze endpoint hit") 
    data = request.json
    try:
        response = main(data)
        return jsonify(response)
    except Exception as e:
        error_message = f"Internal Server Error: {str(e)}"
        emit_log(error_message)
        print(error_message)  # Additional print statement for detailed logging
        return jsonify({"error": error_message}), 500


def main(data):
    question = data.get("question")
    source_code = data.get("source_code")
    contract_name = extract_contract_name(source_code)
    source_code_path = f'./src/{contract_name}.sol'
    solidity_test_path = f'./test/{contract_name}Test.t.sol'
    write_to_file(source_code_path, source_code)

    refined_question = ask_openai([
        {
            "role": 'system',
            "content": 'You are an AI assistant specializing in Solidity smart contract security. Please refine the provided question to focus on potential vulnerabilities and testing requirements for the this contract. Your answer can only return the refined question.'
        },
        {
            "role": "user",
            "content": f"Question: {question}\n Source Code: {source_code}\nPlease refine this question for a smart contract test."
        }
    ])
    emit_log(refined_question)

    solidity_test = ask_openai([
        {
            "role": 'system',
            "content": 'You are adept at creating Solidity tests using Foundry. Generate a test script for the provided Solidity contract that addresses the concerns in the refined question. Your answer can only return the solidity code, and nothing more in your response. Do not provide any unused or wrong variables, functions or packages in your code. Make sure each functions and the paths  are accurate, and do not include any unidentified Identifiers or wrong argument count'
        },
        {
            "role": "user",
            "content": f"Refined Question: {refined_question}\nSource Code: {source_code}\nPath: {source_code_path}\nPlease create a Foundry test script for this contract. Only return the solidity code, and do not provide anything else in your response"
        }
    ])
    emit_log("Generated Test:\n" + solidity_test)

    # Refine the Generated Test
    better_test = ask_openai([
        {
            "role": 'system',
            "content": 'You are an expert in reviewing and optimizing Solidity tests. Review the generated test script for potential improvements, focusing on its effectiveness and relevance to the identified vulnerabilities. Your answer can only return the solidity code, and nothing more in your response. Do not provide any unused or wrong variables, functions or packages in your code. Make sure each functions and the paths are accurate, and do not include any unidentified Identifiers or wrong argument count.'
        },
        {
            "role": "user",
            "content": f"Here is the test file: {solidity_test}\nP lease refine this test script for this question: {refined_question} \n .Return only the optimized Solidity code."
        }
    ])
    emit_log("Refined Test:\n" + clean_test_code(better_test))

    write_to_file(solidity_test_path, clean_test_code(better_test))
    build_successful = False
    current_test_code = solidity_test

    while not build_successful:
        build_output = run_forge_build()

        if ("Error" in build_output or "Warning" in build_output ) and "File not found" not in build_output:
            emit_log("Build Error Detected. Attempting to Fix...")
            emit_log(build_output)
            fixed_test_code = fix_test_code(build_output, current_test_code)
            current_test_code = fixed_test_code
            write_to_file(solidity_test_path, clean_test_code(fixed_test_code))
            emit_log("Fixed Test Code Written to File")
        elif "File not found" in build_output:
            fixed_source_code=fix_import_paths(source_code,build_output)
            current_source_code=fixed_source_code
            write_to_file(solidity_test_path, clean_test_code(fixed_build_code))
            emit_log(current_source_code)
            emit_log("Fixed Source Code Written to File")
        else:
            build_successful = True
            emit_log("Build Successful. No further fixes required.")
    
    forge_test_results = run_forge_test()
    emit_log("Forge Test Results:\n"+ forge_test_results)

    build_output = run_forge_build()
    if "Error" in build_output:
        emit_log("Build Error Detected:"+ build_output)
        return

    forge_test_results = run_forge_test()
    emit_log("Forge Test Results:\n"+ forge_test_results)

    if "FAIL" in forge_test_results:
        while ( "File not found" in forge_test_results  or "Compiler run failed:" in forge_test_results or "revert" in forge_test_results) :
            emit_log("Test Script Error Detected. Attempting to Fix...")
            fixed_test_code = fix_test_code(forge_test_results, solidity_test)
            write_to_file(solidity_test_path, clean_test_code(fixed_test_code))
            emit_log("Fixed Test Code Written to File")

            forge_test_results = run_forge_test()
            emit_log("Re-run Forge Test Results:\n"+ forge_test_results)

            if "FAIL" not in forge_test_results:
                return {"result": "All tests passed", "details": "No vulnerabilities detected based on the current tests."}

        analysis_response = analyze_source_vulnerability(forge_test_results, question, solidity_test, source_code)
        move_files('./src', './contracts', '.sol')
        move_files('./test', './contracts', '.sol')
        clear_directory_contents('./src')
        clear_directory_contents('./test')
        emit_log(analysis_response)
    else:
        move_files('./src', './contracts', '.sol')
        move_files('./test', './contracts', '.sol')
        clear_directory_contents('./src')
        clear_directory_contents('./test')
        return emit_log("All tests passed")




if __name__ == "__main__":
    socketio.run(app, debug=True)

