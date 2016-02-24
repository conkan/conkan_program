var storage = sessionStorage;
$(document).ready(function(){
  $(document).scrollTop( storage.getItem( 'sctop' ) );
  storage.clear();
});
// モーダルダイアログ表示
$('#editRoom').on('show.bs.modal', function (event) {
  var roomid = $(event.relatedTarget).data('whatever');
  var content = $('#editRoomContent');
  $(content).load(roomid + '/ FORM');
  if ( $(event.relatedTarget).data('rmcol') ) {
    $('#dobtn').hide();
    $('#dodel').hide();
  }
  else {
    $('#dobtn').show();
    $('#dodel').show();
  }
} );
// モーダルダイアログ非表示
$('#editRoom').on('hide.bs.modal', function (event) {
  storage.setItem( 'sctop', $(document).scrollTop() );
  location.reload(true);
} );
// 更新
$('#dobtn').click(function(event) {
  if (!$('#name').val()) {
      $('#valerr').text('部屋名は必須です');
      return false;
  }
  if (!$('#roomno').val()) {
      $('#valerr').text('部屋番号は必須です');
      return false;
  }
  if (!$('#type').val()) {
      $('#valerr').text('形式は必須です');
      return false;
  }
  var content = $('#editRoomContent');
  var data = $('#roomform').serializeArray();
  var roomid = $('#roomid').val();
  $('#dobtn').hide();
  $('#dodel').hide();
  $(content).load(roomid + '/edit/ FORM', data );
} );
// 削除
$('#dodel').click(function(event) {
  var content = $('#editRoomContent');
  var data = $('#roomform').serializeArray();
  var roomid = $('#roomid').val();
  $('#dobtn').hide();
  $('#dodel').hide();
  $(content).load(roomid + '/del/ FORM', data );
} );
