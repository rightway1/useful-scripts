FROM hub.docker.com/python36:latest

# Add confd
RUN mkdir -p /opt/confd/bin \
	&& mkdir -p /etc/confd/{templates,confd.d}
RUN yum install -y wget \
	&& wget -O /opt/confd/bin/confd confd-0.11.0-linux-amd64 \
	&& yum -y history undo last \
	&& yum clean all
RUN chmod +x /opt/confd/bin/confd
ADD ci/container/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

# Add confd configuration
ADD ci/container/confd/resource /etc/confd/conf.d/
ADD ci/container/confd/source /etc/confd/templates/

# Add requirements on its own to make sure we only
# re-run when there are changes to requirements.txt
ADD requirements.txt /requirements.txt
RUN pip3 install $PIP_ARGS -r /requirements.txt uwsgi

# Add the api code
ADD app /usr/lib/python3.6/site-packages/app
ADD tests /usr/lib/python3.6/site-packages/tests
ADD autoapp.py /usr/lib/python3.6/site-packages/app/autoapp.py

EXPOSE 5000

HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl --fail --silent http://localhost:5000/v1/spec.json || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
