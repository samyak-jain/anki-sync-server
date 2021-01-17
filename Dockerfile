FROM library/python:3.9.1-buster

RUN apt-get update && apt-get upgrade
RUN apt-get install -y portaudio19-dev

COPY src /app/anki-sync-server

WORKDIR /app/anki-sync-server

RUN pip install -r requirements.txt

RUN mkdir /app/data && \
    mv /app/anki-sync-server/ankisyncd.conf /app/anki-sync-server/ankisyncd.conf.example && \
    ln -s /app/data/ankisyncd.conf /app/anki-sync-server/

COPY config /app/config
COPY scripts /app/scripts

CMD /app/scripts/startup.sh

EXPOSE 27701

HEALTHCHECK --interval=5s --timeout=3s CMD wget -q -O - http://127.0.0.1:27701/ || exit 1
