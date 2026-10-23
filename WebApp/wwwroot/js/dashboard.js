(function () {
  // The menu button opens / closes the side menu on narrow screens.
  var toggle = document.getElementById('menu-toggle');
  var backdrop = document.getElementById('sidebar-backdrop');
  function setSidebar(open) { document.body.classList.toggle('menu-open', open); }

  if (toggle) toggle.addEventListener('click', function () {
    setSidebar(!document.body.classList.contains('menu-open'));
  });
  if (backdrop) backdrop.addEventListener('click', function () { setSidebar(false); });
})();

(function () {
  // Top-right account menu: click the button to open, click elsewhere or press Escape to close.
  var btn = document.getElementById('acct-btn');
  var menu = document.getElementById('acct-menu');
  if (!btn || !menu) return;

  function setOpen(open) {
    menu.hidden = !open;
    btn.setAttribute('aria-expanded', open ? 'true' : 'false');
    btn.classList.toggle('open', open);
  }

  btn.addEventListener('click', function (e) {
    e.stopPropagation();
    setOpen(menu.hidden);
  });
  document.addEventListener('click', function (e) {
    if (!menu.hidden && !menu.contains(e.target)) setOpen(false);
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && !menu.hidden) { setOpen(false); btn.focus(); }
  });
})();
