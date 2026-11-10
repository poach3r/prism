let
  withParsnip = parsnip: import ./lib {inherit parsnip;};
in
  withParsnip null // {__functor = _: {parsnip ? null}: withParsnip parsnip;}
