FROM node:24

RUN mkdir -p /usr/app
WORKDIR /usr/app

RUN apt-get update
RUN apt-get install bash

COPY client ./client
COPY server ./server

COPY build.sh .
COPY pm2.config.js .

RUN bash ./build.sh
RUN npm install pm2 -g

RUN rm build.sh
#RUN rm tsconfig.tsbuildinfo

EXPOSE 8080

CMD [ "pm2-runtime", "start", "pm2.config.js" ]
