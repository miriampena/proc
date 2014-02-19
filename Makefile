REBAR=./rebar

all: compile

compile:
	$(REBAR) compile

clean:
	@$(REBAR) clean

test: all
	@$(REBAR)  ct

xref:
	@$(REBAR) xref
