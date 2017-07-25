import re

from collections import namedtuple
from inspect import *
from pymoku.instruments import *

from jinja2 import Environment, Template, FileSystemLoader

jinja_env = Environment(
    loader=FileSystemLoader('.'),
    trim_blocks=True,
    lstrip_blocks=True)

template = 'mat_obj.templ'

_paragraph_re = re.compile(r'(?:\r\n|\r|\n)+')

def firstline(line):
    return _paragraph_re.split(line)[0]

jinja_env.filters['firstline'] = firstline


def translate_type(param):
    if param is True:
        return "'true'"
    elif param is False:
        return "'false'"
    elif param is None:
        return "'nil'"
    elif isinstance(param, str):
        return "'" + param + "'"
    else:
        return param


def process_object(to_doc):
    funcs = getmembers(to_doc, isfunction)
    outfile = "Moku" + to_doc.__name__ + '.m'

    fspecs = []

    for f in funcs:
        name = f[0]
        args = getargspec(f[1]).args[1:] # cut off self
        defs = list(getargspec(f[1]).defaults or [])
        doc = getdoc(f[1])

        if name.startswith('_'): continue
        if not doc: continue # If there's no docstring then it's not part of the public API

        no_defs = len(args) - len(defs) - 1 # because we nuked 'self' already
        defs = [None] * no_defs + defs

        defs = list(map(translate_type, defs))

        ArgPair = namedtuple('ArgPair', ['name', 'default'])
        arg_pairs = list(map(ArgPair._make, zip(args, defs)))

        fspecs.append({
            'name' : name,
            'args' : arg_pairs,
            'rargs' : list(reversed(arg_pairs)), # works around a bug with reversing length-1 generators
            'docstring' : doc,
            'return' : '',
        })

    env = {
        'functions' : fspecs,
        'classname' : "Moku" + to_doc.__name__,
        'instrumentname' : to_doc.__name__,
    }

    with open(outfile, 'w') as out:
        t = jinja_env.get_template(template)
        
        out.write(t.render(env))

for instr_class in id_table.values():
    if instr_class is None: continue
    process_object(instr_class)
