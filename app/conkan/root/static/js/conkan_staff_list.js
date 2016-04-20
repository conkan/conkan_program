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

// conkanStaffListモジュールの生成(グローバル変数)
var ConkanAppModule = angular.module('conkanStaffList',
    ['ui.grid', 'ui.grid.resizeColumns', 'ui.bootstrap'] );

// スタッフリストコントローラ
ConkanAppModule.controller( 'staffListController',
    [ '$scope', '$sce', '$http', '$uibModal',
        function( $scope, $sce, $http, $uibModal ) {
            $scope.__getRoll = function( role ) {
                var cont;
                switch (role) {
                    case 'NORM':
                        cont = '企画スタッフ';
                        break;
                    case 'PG':
                        cont = '企画管理スタッフ';
                        break;
                    case 'ROOT':
                        cont = 'システム管理者';
                        break;
                }
                var wkstr = $sce.trustAsHtml( cont );
                return wkstr;
            }

            $scope.__getEditbtn = function( rmdate, staffid, role ) {
                var cont = '<button type="button" class="btn btn-xs';
                if ( rmdate ) {
                    cont += '">無効</button>';
                }
                else {
                    cont += ' btn-primary" data-toggle="modal"'
                        + ' data-target="#editStaff" data-whatever="' + staffid
                        + '" data-whatrole="' + role + '">編集</button>';
                }
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
                    width: "23%",
                    cellTemplate: '<div ng-class="{ disableRow: row.entity.rmdate }">{{COL_FIELD}}</div>',
                },
                { name : '役割', field: 'role',
                    headerCellClass: 'gridheader',
                    width: "23%",
                    cellTemplate: '<div ng-class="{ disableRow: row.entity.rmdate }"><span ng-bind-html="grid.appScope.__getRoll(row.entity.role)"></span></div>'
                },
                { name : '担当名', field: 'tname',
                    headerCellClass: 'gridheader',
                    width: "23%",
                    cellTemplate: '<div ng-class="{ disableRow: row.entity.rmdate }">{{COL_FIELD}}</div>',
                },
                { name : '最終ログイン日時', field: 'llogin',
                    headerCellClass: 'gridheader',
                    width: "23%",
                    cellTemplate: '<div ng-class="{ disableRow: row.entity.rmdate }">&nbsp;{{COL_FIELD}}</div>',
                },
                { name : '', field: 'staffid',
                    headerCellClass: 'gridheader',
                    cellTemplate: '<div ng-class="{ disableRow: row.entity.rmdate }" class="gridcelbtn"><span ng-bind-html="grid.appScope.__getEditbtn(row.entity.rmdate, row.entity.staffid, row.entity.role)"></span></div>'
                },
            ];
            $http.get('/config/staff/listget')
            .success(function(data, status, headers, config) {
                $scope.staffgrid.data = data.json;
            })
            .error(function(data, status, headers, config) {
                var modalinstance = $uibModal.open(
                    { templateUrl : 'T_httpget_fail' }
                );
                modalinstance.result.then( function() {} );
            });
        }
    ]
);

// -- EOF --
