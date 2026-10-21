(function () {
  // Show / hide password buttons
  document.querySelectorAll('.pw-toggle').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var input = document.getElementById(btn.getAttribute('data-target'));
      if (!input) return;
      var show = input.type === 'password';
      input.type = show ? 'text' : 'password';
      btn.classList.toggle('is-shown', show);
      btn.setAttribute('aria-label', show ? 'Hide password' : 'Show password');
    });
  });

  // "Forgot password?" is not wired up yet: show a friendly message instead.
  var link = document.getElementById('forgot-link');
  var msg = document.getElementById('forgot-msg');
  if (link && msg) {
    link.addEventListener('click', function (e) {
      e.preventDefault();
      msg.hidden = false;
    });
  }
})();
