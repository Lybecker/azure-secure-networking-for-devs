import os
from datetime import datetime, timezone
from flask import Flask, request
from blob_storage_client import BlobStorageClient

app = Flask(__name__)
team_name = os.getenv('TEAM_NAME')
location = os.getenv('LOCATION') # "eu" or "us"
environment = "dev"
storage_account_names = [f"st{team_name}{environment}{location}", f"st{team_name}{environment}hub"]
all_storage_account_names = [f"st{team_name}{environment}us", f"st{team_name}{environment}hub", f"st{team_name}{environment}eu"]
container_name = "test"
blob_filename = "test.txt"

@app.route('/health')
def health():
   return "OK"

@app.route('/')
def index():
   return f"Hello {team_name}! The UTC time is {datetime.now(timezone.utc)}"

@app.route('/create_blobs')
def create_blobs():
    output: str = f"The UTC time is {datetime.now(timezone.utc)}<br /><br />"

    for storage_account_name in storage_account_names:
        print(f"Creating blob in storage account {storage_account_name}")
        blob_storage_client = BlobStorageClient(storage_account_name)

        try:
            blob_storage_client.create_container(container_name)
            file_path = os.path.join("./", blob_filename)
            blob_storage_client.upload_blob(container_name, file_path)
            output += f"Blob in storage account {storage_account_name} created/exists<br /><br />"
        except Exception as ex:
            output += f"Failed to create blob in storage account {storage_account_name}: {ex}<br /><br />"

    return output

@app.route('/list_blobs')
def list_blobs():
    blobs: str = ""
    output: str = f"The UTC time is {datetime.now(timezone.utc)}<br /><br />"

    for storage_account_name in all_storage_account_names:
        print(f"Getting blobs list in storage account {storage_account_name}")
        blob_storage_client = BlobStorageClient(storage_account_name)
        blobs = ""

        try:
            blobs_list = blob_storage_client.get_blobs_list(container_name)

            for blob in blobs_list:
                blobs += f"{blob.name};"

            output += f"Blob(s) found in storage account {storage_account_name}: {blobs}<br /><br />";
        except Exception as ex:
            output += f"Failed to list blobs in storage account {storage_account_name}: {ex}<br /><br />"

    return output

if __name__ == '__main__':
   app.run()
