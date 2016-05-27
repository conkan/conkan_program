// conkan_prog_detail.js --- 企画詳細表示用 JS ---
/*esLint-env jquery, prototypejs */
(function() {
  var storage = sessionStorage;
  angular.element(document).ready(function(){
    angular.element(document).scrollTop( storage.getItem( 'sctop' ) );
    storage.removeItem( 'sctop' );
  });
  // スクロール制御
  angular.element('.subtag a').click(function(){
    var pd, tp;
    pd = parseInt(angular.element(document.body).css('padding-top'));
    tp = angular.element(this.hash).position().top;
    angular.element(document).scrollTop(tp-pd);
    return false;
  });
  // モーダルダイアログ表示
  angular.element('#PgEdit').on('show.bs.modal', function (event) {
    var pgid   = angular.element(event.relatedTarget).data('whatpgid');
    var id     = angular.element(event.relatedTarget).data('whatitem');
    var target = angular.element(event.relatedTarget).data('whattarget');
    var content = angular.element('#PgEditContent');
    var arg = '/program/' + pgid + '/' + target;
    if ( id != "-" ) {
      arg += '/' + id;
    }
    arg += '/ FORM';
    angular.element(content).load(arg);
    if ( !id ) {
      angular.element('#dobtn').text('追加');
    }
    angular.element('#dobtn').show();
    if ( target != "regprogram" && id ) {
      angular.element('#dodel').show();
    } else {
      angular.element('#dodel').hide();
    }
  } );
  // モーダルダイアログ表示後サイズ調整
  angular.element('#PgEdit').on('shown.bs.modal', function (event) {
    if ( angular.element('#PgEditDialog').outerHeight()
           < angular.element(window).height() ) {
      return;
    }
    var content = angular.element('#PgEditContent');
    var vh = content.offset().top + 1 +
             angular.element('#PgEditFooter').outerHeight() + 
             parseInt( angular.element('#PgEditDialog').css('marginTop')) +
             parseInt( angular.element('#PgEditDialog').css('marginBottom'));
    content.css( 'height', angular.element(window).height() - vh );
  } );
  // モーダルダイアログ非表示
  angular.element('#PgEdit').on('hide.bs.modal', function (event) {
    storage.setItem( 'sctop', angular.element(document).scrollTop() );
    location.reload(true);
  } );
  // 更新/追加
  angular.element('#dobtn').click(function(event) {
    // バリデーション
    var vha = angular.element('#progform #vha').data('vha');
    for ( var i in vha ) {
      if (!angular.element('#'+ vha[i].id).val()) {
        angular.element('#valerr').text(vha[i].name + 'は必須です');
        angular.element('#' + vha[i].id).css('background-color', '#ff8e8e');
        return false;
      }
      else {
        angular.element('#' + vha[i].id).css('background-color', '');
      }
    }
    var content = angular.element('#PgEditContent');
    var data = angular.element('#progform').serializeArray();
    var pgid   = angular.element('#progform #pgid').val();
    var id     = angular.element('#progform #id').val() || 0;
    var target = angular.element('#progform #target').val();
    angular.element('#dobtn').hide();
    angular.element('#dodel').hide();
    var arg = '/program/' + pgid + '/' + target;
    if ( id != "-" ) {
      arg += '/' + id;
    }
    arg += '/ FORM';
    angular.element(content).load(arg, data );
  } );
  // 削除
  angular.element('#dodel').click(function(event) {
    var content = angular.element('#PgEditContent');
    var pgid    = angular.element('#progform #pgid').val();
    var id      = angular.element('#progform #id').val() || 0;
    var target  = angular.element('#progform #target').val();
    var data = angular.element('#progform').serializeArray();
    angular.element('#dobtn').hide();
    angular.element('#dodel').hide();
    var arg = '/program/' + pgid + '/' + target + '/' + id + '/del/ FORM';
    angular.element(content).load(arg, data );
  } );
  // 進捗登録
  angular.element('#addProgress button').click(function(event) {
    storage.setItem( 'sctop', angular.element(document).scrollTop() );
  } );
  // 企画複製分割
  angular.element('#pgcpysepform button').click(function(event) {
    var act  = angular.element(event.target).data('cpysep');
    angular.element('#pgcpysepform #cpysep_act').val(act);
  } );

  // conkanProgDetailモジュールの生成
  var ConkanAppModule = angular.module('conkanProgDetail',
    ['ui.grid', 'ui.grid.resizeColumns', 'ui.grid.pagination', 'ui.bootstrap'] );

  // 企画詳細コントローラ
  ConkanAppModule.controller( 'progDetailController',
    [ '$scope', '$http', '$uibModal',
      function( $scope, $http, $uibModal ) {
        // 企画更新フォーム
        $scope.openPgEditForm = function( pgid ) {
          $scope.pgid = pgid;
          $uibModal.open({
            templateUrl : "T_pgup_program",
            controller  : 'progFormController',
            backdrop    : "static",
            scope       : $scope,
            size        : 'lg',
          });
        };

        // 要望出演者追加フォーム
        $scope.openRegCastForm = function( regpgid, subno, pgid, name ) {
          $scope.prog = {
            regpgid : regpgid,
            subno   : subno,
            pgid    : pgid,
            name    : name,
          };
          $uibModal.open({
            templateUrl : "T_pgup_regcast",
            controller  : 'regcastFormController',
            backdrop    : "static",
            scope       : $scope,
            size        : 'lg',
          });
        };

        // 決定機材更新追加フォーム
        $scope.openEquipForm = function( regpgid, subno, pgid, name, equipid ) {
          $scope.prog = {
            regpgid : regpgid,
            subno   : subno,
            pgid    : pgid,
            name    : name,
            id      : equipid,
          };
          $scope.applyBtnLbl = ( equipid === 0 ) ? '追加' : '更新';
          $uibModal.open({
            templateUrl : "T_pgup_equip",
            controller  : 'equipFormController',
            backdrop    : "static",
            scope       : $scope,
            size        : 'lg',
          });
        };

      }
    ]
  );

  // 企画更新フォームコントローラ
  ConkanAppModule.controller( 'progFormController',
    [ '$scope', '$http', '$uibModal', '$uibModalInstance',
      function( $scope, $http, $uibModal, $uibModalInstance ) {
        // 初期値設定
        angular.element('#valerr').text('');
        $http({
          method  : 'GET',
          url     : '/timetable/' + $scope.pgid
        })
        .success(function(data) {
          $scope.prog = {};
          ProgDataCnv( data, $scope.prog );
        })
        .error(function(data) {
          var modalinstance = $uibModal.open(
              { templateUrl : getTemplate( '' ), }
          );
          modalinstance.result.then( function() {} );
        });
        // 選択肢取得
        $http.get('/config/confget')
        .success(function(data) {
          $scope.conf = ConfDataCnv( data, $scope.conf );
        })
        .error(function(data) {
          var modalinstance = $uibModal.open(
              { templateUrl : getTemplate( '' ), }
          );
          modalinstance.result.then( function() {} );
        });
        // 監視設定
        $scope.$watch('prog.date1', function( n, o, scope ) {
          if ( n != o ) {
            scope.conf['hours1'] = GetHours(n, scope.conf, scope.prog, '1' );
          }
        });
        $scope.$watch('prog.date2', function( n, o, scope ) {
          if ( n != o ) {
            scope.conf['hours2'] = GetHours(n, scope.conf, scope.prog, '2');
          }
        });
        // 更新実施
        $scope.prgdoApply = function() {
          // 二重クリック回避
          var pgid = $scope.prog.pgid;
          angular.element('#prgapplybtn').attr('disabled', 'disabled');
          // バリデーション
          if ( ProgTimeValid( $scope.prog, $scope.conf.scale_hash ) ) {
            angular.element('#valerr').text('時刻設定に矛盾があります');
            angular.element('#prgapplybtn').removeAttr('disabled');
            return;
          }
          $http( {
            method : 'POST',
            url : '/timetable/' + pgid,
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            data: $.param($scope.prog)
          })
          .success(function(data) {
            // templateを一つにまとめたいところ
            var modalinstance;
            $uibModalInstance.close('done');
            modalinstance = $uibModal.open(
              {
                templateUrl : getTemplate( data.status ),
                backdrop    : 'static'
              }
            );
            modalinstance.result.then( function() {
              location.reload();
            });
          })
          .error(function(data) {
            $uibModalInstance.close('done');
            var modalinstance = $uibModal.open(
              {
                templateUrl : getTemplate( '' ),
                backdrop    : 'static'
              }
            );
            modalinstance.result.then( function() {
              location.reload();
            });
          });
        };
      }
    ]
  );

  // 要望出演者追加フォームコントローラ
  ConkanAppModule.controller( 'regcastFormController',
    [ '$scope', '$http', '$uibModal', '$uibModalInstance',
      function( $scope, $http, $uibModal, $uibModalInstance ) {
        // 初期値設定
        angular.element('#valerr').text('');
        $scope.regcast = {
          regpgid : $scope.prog.regpgid,
          pgid : $scope.prog.pgid,
          name : '', namef : '', regno : '',
          title : '', needreq : '', needguest : '',
        };
        // 選択肢取得
        $http.get('/config/confget')
        .success(function(data) {
          $scope.conf = ConfDataCnv( data, $scope.conf );
        })
        .error(function(data) {
          var modalinstance = $uibModal.open(
            { templateUrl : getTemplate( '' ), }
          );
          modalinstance.result.then( function() {} );
        });
        // 登録実施
        $scope.regcastdoApply = function() {
          // 二重クリック回避
          angular.element('#regcastapplybtn').attr('disabled', 'disabled');
          $http( {
            method : 'POST',
            url : '/program/regcastadd',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            data: $.param($scope.regcast)
          })
          .success(function(data) {
            // templateを一つにまとめたいところ
            var modalinstance;
            $uibModalInstance.close('done');
            modalinstance = $uibModal.open(
              {
                templateUrl : getTemplate( data.status ),
                backdrop    : 'static'
              }
            );
            modalinstance.result.then( function() {
              location.reload();
            });
          })
          .error(function(data) {
            $uibModalInstance.close('done');
            var modalinstance = $uibModal.open(
              {
                templateUrl : getTemplate( '' ),
                backdrop    : 'static'
              }
            );
            modalinstance.result.then( function() {
              location.reload();
            });
          });
        };
      }
    ]
  );

  // 決定機材更新追加フォームコントローラ
  ConkanAppModule.controller( 'equipFormController',
    [ '$scope', '$http', '$uibModal', '$uibModalInstance',
      function( $scope, $http, $uibModal, $uibModalInstance ) {
        // 初期値設定
        angular.element('#valerr').text('');
        $http({
          method  : 'GET',
          url     : '/program/' + $scope.prog.pgid + '/equip/' + $scope.prog.id
        })
        .success(function(data) {
          $scope.equip = {
            pgid    : data.json.pgid,
            equipid : data.json.equipid,
            spec    : '',
            comment : '',
          };
          $scope.maxequipid = data.json.maxequipid;
          $scope.equiplist = data.json.equiplist;
          $scope.equipdata = data.json.equipdata;
        })
        .error(function(data) {
          var modalinstance = $uibModal.open(
              { templateUrl : getTemplate( '' ), }
          );
          modalinstance.result.then( function() {} );
        });
        // 監視設定
        $scope.$watch('equip.equipid', function( n, o, scope ) {
          if ( n < scope.maxequipid ) {
            scope.served = true;
            scope.equip.spec    = scope.equipdata[n].spec;
            scope.equip.comment = scope.equipdata[n].comment;
          }
          else {
            scope.served = false;
          }
        });
        // 更新実施
        $scope.equipDoApply = function() {
          var pgid = $scope.prog.pgid;
          var itemid = $scope.prog.id;
          // 二重クリック回避
          angular.element('#equipapplybtn').attr('disabled', 'disabled');
          // バリデーション
          //    現在なし
          // 新規追加時、equipidはNULL
          if ( $scope.equip.equipid > $scope.maxequipid ) {
            $scope.equip.equipid = null;
          }
          // 実行
          $http( {
            method : 'POST',
            url : '/program/' + pgid + '/equip/' + itemid,
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            data: $.param($scope.equip)
          })
          .success(function(data) {
            // templateを一つにまとめたいところ
            var modalinstance;
            $uibModalInstance.close('done');
            modalinstance = $uibModal.open(
              {
                templateUrl : getTemplate( data.status ),
                backdrop    : 'static'
              }
            );
            modalinstance.result.then( function() {
              location.reload();
            });
          })
          .error(function(data) {
            $uibModalInstance.close('done');
            var modalinstance = $uibModal.open(
              {
                templateUrl : getTemplate( '' ),
                backdrop    : 'static'
              }
            );
            modalinstance.result.then( function() {
              location.reload();
            });
          });
        };
        // 削除実施
        $scope.equipDoDel = function() {
          var pgid = $scope.prog.pgid;
          var itemid = $scope.prog.id;
          // 二重クリック回避
          angular.element('#equipapplybtn').attr('disabled', 'disabled');
          $http( {
            method : 'POST',
            url : '/program/' + pgid + '/equip/' + itemid + '/del/',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
          })
          .success(function(data) {
            // templateを一つにまとめたいところ
            var modalinstance;
            $uibModalInstance.close('done');
            modalinstance = $uibModal.open(
              {
                templateUrl : getTemplate( data.status ),
                backdrop    : 'static'
              }
            );
            modalinstance.result.then( function() {
              location.reload();
            });
          })
          .error(function(data) {
            $uibModalInstance.close('done');
            var modalinstance = $uibModal.open(
              {
                templateUrl : getTemplate( '' ),
                backdrop    : 'static'
              }
            );
            modalinstance.result.then( function() {
              location.reload();
            });
          });
        };
      }
    ]
  );

  // 進捗リストコントローラ
  ConkanAppModule.controller( 'progressListController',
    [ '$scope', '$sce', '$http', '$uibModal', 'uiGridConstants',
      function( $scope, $sce, $http, $uibModal, uiGridConstants ) {
        var pageSize = 5;
        $scope.progressgrid = {
          enableFiltering: false,
          enableSorting: false,
          treeRowHeaderAlwaysVisible: false,
          enableColumnResizing: true,
          enableGridMenu: false,
          paginationPageSize: pageSize,
          paginationPageSizes: [ pageSize ],
          useExternalPagination: true,
          enableHorizontalScrollbar: uiGridConstants.scrollbars.NEVER,
          enableVerticalScrollbar: uiGridConstants.scrollbars.NEVER,
          onRegisterApi: function(gridApi) {
            $scope.gridApi = gridApi;
            gridApi.pagination.on.paginationChanged($scope, function(nPage) {
              getPage(nPage);
            });
          }
        };

        $scope.progressgrid.columnDefs = [
          { name : '報告日時', field : 'repdatetime',
            headerCellClass: 'gridheader',
            width: "17%",
            cellClass: 'ui-grid-vcenter',
            enableHiding: false,
          },
          { name : '報告者', field : 'tname',
            headerCellClass: 'gridheader',
            width: "17%",
            cellClass: 'ui-grid-vcenter',
            enableHiding: false,
          },
          { name : '内容', field : 'report',
            headerCellClass: 'gridheader',
            cellClass: 'ui-grid-vcenter',
            enableHiding: false,
          },
        ];
        var getPage = function( newPage ) {
          var pgid = angular.element('#progress_pgid').val();
          var url = '/program/' + pgid + '/progress/'
                      + newPage + '/' + pageSize + '/';
          $http.get(url)
          .success(function(data) {
            $scope.progressgrid.totalItems = data.totalItems;
            $scope.progressgrid.data = data.json;
          })
          .error(function(data) {
            var modalinstance = $uibModal.open(
              { templateUrl : getTemplate( '' ), }
            );
            modalinstance.result.then( function() {} );
          });
        };

        getPage(1);
      }
    ]
  );
})();
// -- EOF --
