var storage = sessionStorage;
$(document).ready(function(){
  $(document).scrollTop( storage.getItem( 'sctop' ) );
  storage.clear();
});
// モーダルダイアログ表示
$('#editEquip').on('show.bs.modal', function (event) {
  var equipid = $(event.relatedTarget).data('whatever');
  var content = $('#editEquipContent');
  $(content).load(equipid + '/ FORM');
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
$('#editEquip').on('hide.bs.modal', function (event) {
  storage.setItem( 'sctop', $(document).scrollTop() );
  location.reload(true);
} );
// 更新
$('#dobtn').click(function(event) {
  if (!$('#name').val()) {
      $('#valerr').text('名称は必須です');
      return false;
  }
  if (!$('#equipno').val()) {
      $('#valerr').text('機材番号は必須です');
      return false;
  }
  var content = $('#editEquipContent');
  var data = $('#equipform').serializeArray();
  var equipid = $('#equipid').val();
  $('#dobtn').hide();
  $('#dodel').hide();
  $(content).load(equipid + '/edit/ FORM', data );
} );
// 削除
$('#dodel').click(function(event) {
  var content = $('#editEquipContent');
  var data = $('#equipform').serializeArray();
  var equipid = $('#equipid').val();
  $('#dobtn').hide();
  $('#dodel').hide();
  $(content).load(equipid + '/del/ FORM', data );
} );
