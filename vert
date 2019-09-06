#!/usr/bin/env python3
# Copyright 2019 Erin Atkinson

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from fire import Fire
from flask import Flask, flash, redirect, render_template_string, request
from hashlib import md5
from json import dump as j_dump, dumps as j_dumps, loads as j_loads
from os.path import splitext
from pathlib import Path
from sys import stderr
from threading import Thread
from time import sleep
from webbrowser import open_new
from werkzeug.utils import secure_filename
from yaml import dump as y_dump, load as y_load, SafeLoader
web = Flask(__name__)
api = Flask(__name__)
###
# Vert
# This program is a simple converter between yaml and json.
###


def to_yaml(in_file, out_file=""):
    """to_yaml is the entrypoint for the to_yaml conversion
       takes an in_file string, and optional out_file string
       and passes it to the convert function with a yaml to_type"""
    convert(in_file, out_file, "yaml")


def to_json(in_file, out_file=""):
    """to_json is the entrypoint for the to_json conversion
       takes an in_file string, and optional out_file string
       and passes it to the convert function with a json to_type"""
    convert(in_file, out_file, "json")


def apiserver(port=8080):
    """apiserver is the entrypoint for running an api server that
       listens on the /api/v1/upload path for a multipart upload file
       of either yaml or json and returns the converted data."""
    srv = Thread(target=run_apiserver, args=(port, ), daemon=True)
    srv.start()
    try:
        while True:
            sleep(2)
            continue
    except KeyboardInterrupt:
        return


def webserver(port=8888):
    """webserver is the entrypoint for running a webserver to process
       the conversion. It starts a flask webserver in a daemon thread
       and opens up the default browser to the upload page and spins
       in a sleep cycle until a keyboard interrupt happens. This
       ensures that the webserver doesn't stop until the user has
       completed the conversion."""
    srv = Thread(target=run_webserver, args=(port, ), daemon=True)
    srv.start()
    open_new(f"http://localhost:{port}/upload")
    try:
        while True:
            sleep(2)
            continue
    except KeyboardInterrupt:
        return


def convert(in_file, out_file, to_type):
    # convert is the main runner for the cli conversion, and calls the
    #   convert_string function to write out the converted string data
    #   and writes it to the parsed out_file string.
    with open(in_file, 'r') as fp_in:
        with open(parse_out_file(in_file, out_file, to_type), 'w') as fp_out:
            fp_out.write(convert_string(fp_in.read(), to_type))


def parse_out_file(in_file, out_file, type):
    # parse_out_file runs as a helper for the main entrypoints
    # to be able to use the input filename as the base for the
    # output file.
    if out_file != "":
        return out_file
    else:
        return f"{splitext(in_file)[0]}.{type}"


def convert_string(in_data, to_type):
    # convert_string is the main conversion engine for all entrypoints.
    #   will convert in_data, assumes that between yaml/json, whichever
    #   the to_type is, the in_data is the opposite.
    if to_type == "yaml":
        return y_dump(j_loads(in_data))
    elif to_type == "json":
        return j_dumps(y_load(in_data, Loader=SafeLoader), indent=2)
    else:
        raise Exception(f"Invalid conversion type: {to_type}")


def run_webserver(port):
    # run_webserver is the main runner for the webserver, it actually
    #   starts the flask webserver, and is meant to be run in a thread.
    web.secret_key = "<q>hPN;]e]f+ii#7FK9topR,%H'j[7d_Mz3"
    web.config['SESSION_TYPE'] = 'filesystem'
    web.run(port=port, debug=False, use_reloader=False, use_debugger=False)


def run_apiserver(port):
    print(f"Starting api server on port {port}")
    print(f"Active endpoint is at http://localhost:{port}/api/v1/upload")
    api.run(port=port, debug=False, use_reloader=False, use_debugger=False)


@web.route("/upload", methods=['GET', 'POST'])
def upload():
    # upload is the handler for the main webserver path, and handles all upload
    #   parsing and displaying of the converted data.
    if request.method == "POST":
        file_, filename, err = check_and_get_file(request.files)
        # yes I know this is golangish so sue me.
        if err != None:
            flash(err)
            return redirect(request.url)
        try:
            data, err = server_conversion(file_, filename)
            # yes I know this is golangish so sue me.
            if err != None:
                flash(err)
                return redirect(request.url)
            return render_template_string(web_template, converting=True, data=data)
        except Exception as e:
            flash(f"Error: {e}")
            return redirect(request.url)

    else:
        return render_template_string(web_template, converting=False, data=None)


@api.route("/api/v1/upload", methods=["POST"])
def api_upload():
    # api_upload is the handler for the main api path, and handles all upload
    #   parsing and returning of converted data.

    file_, filename, err = check_and_get_file(request.files)
    # yes I know this is golangish so sue me.
    if err != None:
        return err, 400
    try:
        data, err = server_conversion(file_, filename)
        # yes I know this is golangish so sue me.
        if err != None:
            return err, 415
        return data
    except Exception as e:
        return f"Error: {e}", 500


def check_and_get_file(files):
    if "file" not in files:
        return (None, "No file part")
    file_ = files["file"]
    if file_.filename == "":
        return (None, "No selected file")
    return (file_, secure_filename(file_.filename), None)


def server_conversion(file_, filename):
    extension = splitext(filename)
    if extension[1] in [".yaml", ".yml"]:
        return (convert_string(file_.read(), "json"), None)
    elif extension[1] in [".json"]:
        return (convert_string(file_.read(), "yaml"), None)
    else:
        return (None, f"Unhandled extension: {extension[1]}, please choose a file that has a .yaml, .yml, or .json extension.")


# The following are the html templates for the webserver.
web_template = """
<html>
    <head>
        <title>Vert: A YAML/JSON converter</title>
        <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css" integrity="sha384-HSMxcRTRxnN+Bdg0JdbxYKrThecOKuH5zCYotlSAcp1+c8xmyTe9GYg1l9a69psu" crossorigin="anonymous">
        <script src="https://code.jquery.com/jquery-1.12.4.min.js" integrity="sha384-nvAa0+6Qg9clwYCGGPpDQLVpLNn0fRaROjHqs13t4Ggj3Ez50XnGQqc/r8MhnRDZ" crossorigin="anonymous"></script>
        <script src="https://stackpath.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js" integrity="sha384-aJ21OjlMXNL5UyIl/XNwTMqvzeRMZH2w8c5cRVpzpU8Y5bApTppSuUkhZXN0VxHd" crossorigin="anonymous"></script>
    </head>
    <body>

        <div class="container">
            <div class="header clearfix">
                <h3 class="text-muted">Vert: A YAML/JSON converter</h3>
            </div>
{% if converting %}
            <div class="jumbotron">
                <h1> Converted Data </h1>
                <pre><code>{{ data | safe }}</code></pre>
            </div>
{% else %}
            <div class="jumbotron">
                <h1> Local Upload </h1>
                <p class="lead">Upload File to the local server, (Note, when running this locally the data will not leave your computer). </p>
                <form method=post enctype=multipart/form-data>
                    <input class="btn btn-lg btn-info" type=file name=file>
                    <br />
                    <input class="btn btn-lg btn-success" type=submit value=Upload>
                </form>
                <p class="lead">
{% for message in get_flashed_messages() %}
                    <div class="flash">{{ message }}</div>
{% endfor %}
                </p>
            </div>
{% endif %}
            <footer class="footer">
                <p>&copy; 2019 Erin Atkinson</p>
            </footer>
        </div> <!-- /container -->
    </body>
</html>
"""

# This is the main entrypoint for the program. Any new
#   cli commands/entrypoints must be added to the dict to
#   be made public by the Fire library.
if __name__ == "__main__":
    Fire({
        "to_yaml": to_yaml,
        "to_json": to_json,
        "webserver": webserver,
        "apiserver": apiserver,
    })
