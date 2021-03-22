import socket
from multiprocessing import Process, Queue

import pytest
import requests

from app import app_factory


# The scope of this fixture should be "module", otherwise various hooks
# such as after_request() are run multiple times per request.
@pytest.fixture(scope="module")
def external_app():
    """Create an external application for testing.

    Unlike app_context above, this function spawns a new process.  This gives up a service
    that also includes Werkzeug.

    :return: (app, root), where app is the application and root is the top-level url.
    """
    app = app_factory(testing=True)

    queue = Queue()
    server = Process(target=spawn_external, args=(app, queue))
    server.start()

    root = queue.get()

    # It is likely that the app is not ready to process queries yet.  Loop
    # with a timeout until it is.
    # See https://stackoverflow.com/questions/30548758/how-do-i-know-that-the-flask-application-is-ready-to-process-the-requests-withou
    for _ in range(10):
        try:
            requests.get(root, timeout=2)
            break
        except requests.exceptions.ConnectionError:
            pass
    else:
        raise RuntimeError("Unable to connect to app on %s" % root)

    yield app, root

    server.terminate()
    server.join()


def spawn_external(app, queue):
    """Run the flask application in a separate process.

    :param app: the flask application
    :param queue: a queue that will contain the host/port to which the app is listening
    :return: None
    """
    # We bind a socket to the first available ephemeral port, close the socket and
    # reuse that port hoping that the race condition doesn't catch up with us, then
    # put the resulting root URL in the queue, then run the app.
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.bind(('127.0.0.1', 0))
    port = sock.getsockname()[1]
    sock.close()

    queue.put("http://127.0.0.1:%s/" % port)

    app.run(host="127.0.0.1", port=port)
