import os
from datetime import datetime

def get_jupyterhub_user():
    """
    Fetch the current JupyterHub username from the environment.
    """
    return os.getenv("JUPYTERHUB_USER", "unknown")


def current_timestamp():
    """
    Return the current UTC timestamp as an ISO-formatted string.
    """
    return datetime.utcnow().isoformat()


def safe_mkdir(path):
    """
    Create a directory if it doesn't exist.
    """
    os.makedirs(path, exist_ok=True)


def join_path(*parts):
    """
    Safely join multiple path parts into a single path.
    """
    return os.path.join(*parts)

