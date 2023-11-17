.PHONY: all compile xref clean server client

all: CA compile xref

server:
	rebar3 shell --sname server --apps ssl,ranch,cowboy

client:
	rebar3 shell --sname client --apps ssl,gun

compile:
	rebar3 compile

xref:
	rebar3 xref

CA:
	git clone --depth 1 https://github.com/etnt/myca.git CA

clean:
	rebar3 clean
