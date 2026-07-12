import os
import subprocess
from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase Admin SDK
# In Cloud Run, the default service account automatically has credentials if configured.
firebase_admin.initialize_app(options={'projectId': 'edtech-innovate'})
db = firestore.client()

app = Flask(__name__)

# The mount path where GCS FUSE attaches the bucket
# You will configure this path in Cloud Run settings.
MOUNT_PATH = os.environ.get('MNT_DIR', '/mnt/firebase_bucket')

@app.route('/sync', methods=['POST'])
def sync_video():
    data = request.get_json()
    
    video_id = data.get('videoId')
    url = data.get('url')
    uid = data.get('uid')
    title = data.get('title', 'Synced YouTube Video')

    if not video_id or not url or not uid:
        return jsonify({"error": "Missing required parameters (videoId, url, uid)"}), 400

    # Ensure the target directory exists in the mounted bucket
    target_dir = os.path.join(MOUNT_PATH, 'course_materials', uid, 'youtube_syncs')
    os.makedirs(target_dir, exist_ok=True)
    
    # Destination file path
    file_path = os.path.join(target_dir, f"{video_id}.mp4")

    try:
        print(f"Starting download for {url} directly to {file_path}")
        
        # Run yt-dlp directly to the mounted GCS bucket
        # Force mp4 format for broad compatibility
        command = [
            'yt-dlp',
            '-f', 'best[ext=mp4]/best',
            '-o', file_path,
            url
        ]
        
        subprocess.run(command, check=True)
        
        # Determine the public URL based on the bucket name
        bucket_name = os.environ.get('BUCKET_NAME', 'your-firebase-project.appspot.com')
        relative_path = f"course_materials/{uid}/youtube_syncs/{video_id}.mp4"
        public_url = f"https://storage.googleapis.com/{bucket_name}/{relative_path}"

        print(f"Download complete. Saving to Firestore...")

        # Update Firestore
        doc_ref = db.collection('course_materials').document()
        doc_ref.set({
            'teacherId': uid,
            'title': title,
            'videoUrl': public_url,
            'source': 'youtube',
            'originalVideoId': video_id,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'isVisible': True,
            'views': 0,
            'likesCount': 0,
            'helpfulCount': 0,
            'commentsCount': 0,
            'isSyllabusBased': False, 
        })

        return jsonify({"success": True, "videoUrl": public_url, "docId": doc_ref.id}), 200

    except subprocess.CalledProcessError as e:
        print(f"yt-dlp error: {e}")
        return jsonify({"error": "Failed to download video"}), 500
    except Exception as e:
        print(f"Unexpected error: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
