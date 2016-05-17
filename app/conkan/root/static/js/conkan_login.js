// conkan_login.js --- ログインページ用 JS ---
/*esLint-env jquery, prototypejs */
$('#dobtn').click(function(event) {
  if ( !$('#passwd').val() ) {
    $('#valerr').text('パスワードは必須です');
    return false;
  }
});

// --- EOF ---
