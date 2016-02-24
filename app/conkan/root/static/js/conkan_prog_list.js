// 追加実施時、ボタンを無効にする
$('#doadd').click(function(event) {
  $('#doadd').addClass('disabled');
  $('#cancel').addClass('disabled');
  return true;
} );
// モーダルダイアログ addProgram 表示
$('#addProgram').on('show.bs.modal', function (event) {
  $('#jsoninputfile').val('');
} );
// モーダルダイアログ addProgram非表示
$('#addProgram').on('hide.bs.modal', function (event) {
  location.reload(true);
} );
