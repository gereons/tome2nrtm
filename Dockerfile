FROM swiftdocker/swift

COPY . /tome2nrtm
WORKDIR /tome2nrtm

ENTRYPOINT ["swift", "run", "tome2nrtm"]
