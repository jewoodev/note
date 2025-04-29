```yml
services:
  mongodb:
    image: mongodb/mongodb-community-server:7.0.16-ubuntu2204
    container_name: mongodb_boot
    restart: always
    ports:
      - 27017:27017
    volumes:
      - ./data:/data
    environment:
      - MONGO_INITDB_ROOT_USERNAME={your username}
      - MONGO_INITDB_ROOT_PASSWORD={your password}
```