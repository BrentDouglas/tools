[
  TMPL_TEMPLATES
].forEach(it => {
  const req = new XMLHttpRequest();
  req.open('GET', "/base/" + it, false);
  req.send(null);

  if (req.status !== 200) {
    throw req.responseText;
  }
  document.body.lastChild.insertAdjacentHTML('afterend', req.responseText);
});