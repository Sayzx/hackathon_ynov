from flask import Flask, request, jsonify, Response
from flask_cors import CORS
import requests
import json
import os

app = Flask(__name__)
CORS(app)

OLLAMA_URL = os.getenv('OLLAMA_URL', 'http://localhost:11434')
DEFAULT_MODEL = os.getenv('DEFAULT_MODEL', 'phi3.5')

@app.route('/api/generate', methods=['POST'])
def generate():
    """Proxy pour Ollama avec streaming support"""
    data = request.json
    prompt = data.get('prompt', '')
    model = data.get('model', DEFAULT_MODEL)
    stream = data.get('stream', True)

    if not prompt:
        return jsonify({'error': 'Prompt manquant'}), 400

    try:
        response = requests.post(
            f'{OLLAMA_URL}/api/generate',
            json={
                'model': model,
                'prompt': prompt,
                'stream': stream
            },
            stream=stream,
            timeout=300
        )
        response.raise_for_status()

        if stream:
            def generate_stream():
                full_response = ""
                for chunk in response.iter_lines():
                    if chunk:
                        data = json.loads(chunk)
                        full_response += data.get('response', '')
                        yield f"data: {json.dumps({'response': data.get('response', ''), 'done': data.get('done', False)})}\n\n"
            return Response(generate_stream(), mimetype='text/event-stream')
        else:
            return jsonify(response.json())

    except requests.exceptions.ConnectionError:
        return jsonify({'error': 'Impossible de se connecter à Ollama sur localhost:11434'}), 503
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/models', methods=['GET'])
def list_models():
    """Liste les modèles disponibles"""
    try:
        response = requests.get(f'{OLLAMA_URL}/api/tags', timeout=10)
        response.raise_for_status()
        return jsonify(response.json())
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    """Vérifier la connexion à Ollama"""
    try:
        response = requests.get(f'{OLLAMA_URL}/api/tags', timeout=5)
        if response.status_code == 200:
            return jsonify({'status': 'ok', 'ollama': 'connected'})
        return jsonify({'status': 'error', 'ollama': 'unreachable'}), 503
    except:
        return jsonify({'status': 'error', 'ollama': 'unreachable'}), 503

if __name__ == '__main__':
    print("🚀 Serveur démarré sur http://localhost:5000")
    print("📡 Proxy Ollama: http://localhost:11434")
    app.run(debug=True, port=5000)
