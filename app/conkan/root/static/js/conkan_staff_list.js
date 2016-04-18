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

// conkanStaffListモジュールの取得(生成済のもの)
var ConkanAppModule = angular.module('conkanStaffList' );

// スタッフリストコントローラ
ConkanAppModule.controller( 'staffListController',
    [ '$scope', 'uiGridConstants', 'staffValue', '$sce',
        function( $scope, uiGridConstants, staffValue, $sce ) {
            $scope.__htmlsce = function( cont ) {
                var wkstr = $sce.trustAsHtml( cont );
                return wkstr;
            };
            $scope.staffgrid = {
                enableFiltering: false,
                enableSorting: true,
                treeRowHeaderAlwaysVisible: false,
                enableColumnResizing: true,
                enableGridMenu: false,
            };
            $scope.staffgrid.columnDefs = [
                { name : '名前', field: 'name',
                    headerCellClass: 'gridheader',
                    cellTemplate: '<div class="ui-grid-cell-contents" ng-bind-html="grid.appScope.__htmlsce(row.entity.name)"></div>',
                },
                { name : '役割', field: 'role',
                    headerCellClass: 'gridheader',
                    cellTemplate: '<div class="ui-grid-cell-contents" ng-bind-html="grid.appScope.__htmlsce(row.entity.role)"></div>',
                },
                { name : '担当名', field: 'tname',
                    headerCellClass: 'gridheader',
                    cellTemplate: '<div class="ui-grid-cell-contents" ng-bind-html="grid.appScope.__htmlsce(row.entity.tname)"></div>',
                },
                { name : '最終ログイン日時', field: 'llogin',
                    headerCellClass: 'gridheader',
                    cellTemplate: '<div class="ui-grid-cell-contents" ng-bind-html="grid.appScope.__htmlsce(row.entity.llogin)"></div>',
                },
                { name : '', field: 'staffid',
                    headerCellClass: 'gridheader',
                    cellTemplate: '<div class="ui-grid-cell-contents" ng-bind-html="grid.appScope.__htmlsce(row.entity.staffid)"></div>',
                },
            ];
            $scope.staffgrid.data = staffValue.stafflist;
        }
    ]
);

// -- EOF --
