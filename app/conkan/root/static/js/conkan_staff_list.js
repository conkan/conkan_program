var storage = sessionStorage;
$(document).ready(function(){
  $(document).scrollTop( storage.getItem( 'sctop' ) );
  storage.clear();
});
$('#editStaff').on('show.bs.modal', function (event) {
  var staffid = $(event.relatedTarget).data('whatever');
  var role = $(event.relatedTarget).data('whatrole');
  var content = $('#editStaffContent');
  $(content).load(staffid + '/ FORM', '', function() {
      $('#' + role).prop('selected', true);
    }
  );
  $('#dobtn').show();
  $('#dodel').show();
} );
$('#editStaff').on('hide.bs.modal', function (event) {
  storage.setItem( 'sctop', $(document).scrollTop() );
  location.reload(true);
} );
$('#dobtn').click(function(event) {
  if (!$('#account').val()) {
      $('#valerr').text('アカウントは必須です');
      return;
  }
  if ( $('#passwd').val() ) {
      if ( $('#passwd').val() != $('#passwd2').val() ) {
          $('#valerr').text('パスワードとパスワード(確認)が一致しません');
          return;
      }
  }
  var content = $('#editStaffContent');
  var data = $('#profform').serializeArray();
  var staffid = $('#staffid').val();
  $('#dobtn').hide();
  $('#dodel').hide();
  $(content).load(staffid + '/edit/ FORM', data );
} );
$('#dodel').click(function(event) {
  var content = $('#editStaffContent');
  var data = $('#profform').serializeArray();
  var staffid = $('#staffid').val();
  $('#dobtn').hide();
  $('#dodel').hide();
  $(content).load(staffid + '/del/ FORM', data );
} );
