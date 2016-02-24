var storage = sessionStorage;
$(document).ready(function(){
  $(document).scrollTop( storage.getItem( 'sctop' ) );
  storage.clear();
});
// モーダルダイアログ表示
$('#editCast').on('show.bs.modal', function (event) {
  var castid = $(event.relatedTarget).data('whatever');
  var content = $('#editCastContent');
  $(content).load(castid + '/ FORM');
  $('#dobtn').show();
} );
// モーダルダイアログ非表示
$('#editCast').on('hide.bs.modal', function (event) {
  storage.setItem( 'sctop', $(document).scrollTop() );
  location.reload(true);
} );
// 更新
$('#dobtn').click(function(event) {
  if (!$('#name').val()) {
      $('#valerr').text('氏名は必須です');
      return false;
  }
  var content = $('#editCastContent');
  var data = $('#castform').serializeArray();
  var castid = $('#castid').val();
  $('#dobtn').hide();
  $(content).load(castid + '/edit/ FORM', data );
} );
