import traceback

def print_exceptions(fun):
    def fun2(*args, **kwargs):
        try:
            return fun(*args, **kwargs)
        except Exception as e:
            traceback.print_exc()
    return fun2
