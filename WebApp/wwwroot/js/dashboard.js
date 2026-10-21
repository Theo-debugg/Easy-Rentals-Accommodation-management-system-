(function () {
  // The menu button opens / closes the side menu on narrow screens.
  var toggle = document.getElementById('menu-toggle');
  var backdrop = document.getElementById('sidebar-backdrop');
  function setOpen(open) { document.body.classList.toggle('menu-open', open); }

  if (toggle) toggle.addEventListener('click', function () {
    setOpen(!document.body.classList.contains('menu-open'));
  });
  if (backdrop) backdrop.addEventListener('click', function () { setOpen(false); });
})();
