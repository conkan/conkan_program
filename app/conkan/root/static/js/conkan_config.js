// conkan_config.js --- システム設定 JS ---
/*esLint-env jquery, prototypejs */
(function() {
  // conkanConfigモジュールの生成
  var ConkanAppModule = angular.module('conkanConfig',
    ['ui.grid', 'ui.grid.resizeColumns', 'ui.bootstrap'] );

  // システム設定コントローラ
  ConkanAppModule.controller( 'configController',
    [ '$scope', '$sce', '$http', '$uibModal',
      function( $scope, $sce, $http, $uibModal ) {
        // システム設定ダイアログ
        $scope.openConfForm = function( staffid ) {
          $uibModal.open({
            templateUrl : 'T_conf_setting',
            controller  : 'confFormController',
            backdrop    : 'static',
            scope       : $scope,
            size        : 'lg',
          });
        };
      }
    ]
  );

  // システム設定ダイアログコントローラ
  ConkanAppModule.controller( 'confFormController',
    [ '$scope', '$http', '$uibModal', '$uibModalInstance',
      function( $scope, $http, $uibModal, $uibModalInstance ) {
        // 初期値設定
        angular.element('#valerr').text('');
        $http({
          method  : 'GET',
          url     : uriprefix + '/config/setting'
        })
        .success(function(data) {
          if ( data.status === 'ok' ) {
            $scope.conf = data.json;
          }
          else {
            $uibModalInstance.close('done');
            if ( data.status != 'accessdeny' ) { // アクセス不正なら何もしない
              var resultDlg = $uibModal.open(
                {
                  templateUrl : getTemplate( data.status ),
                  backdrop    : 'static',
                }
              );
              resultDlg.rendered.then( function() {
                angular.element('.modal-dialog').draggable({handle: '.modal-header'});
              });
              resultDlg.result.then( function() {} );
            }
          }
        })
        .error( function() { httpfailDlg( $uibModal ); } )
        .finally( dialogResizeDrag );

        // 更新実施
        $scope.confDoApply = function() {
          // 二重クリック回避
          angular.element('#confapplybtn').attr('disabled', 'disabled');
          // バリデーション
          // すべてがJSONとして正しいかチェック
          var checkHash = {};
          var isfail = false;
          angular.forEach( $scope.conf, function( val, key ) {
            angular.element('*[name=' + key + ']').each(function() {
              try {
                checkHash[key] = angular.fromJson( val.pg_conf_value );
                if ( angular.isObject( checkHash[key] ) ) {
                  elmSetValid( this, true );
                }
                else {
                  elmSetValid( this, false );
                  isfail = true;
                }
              }
              catch (e) {
                elmSetValid( this, false );
                isfail = true;
              }
            });
          });
          if ( isfail ) {
            angular.element('#valerr').text('入力値の形式が不正です');
            angular.element('#confapplybtn').removeAttr('disabled');
            return;
          }
          // 項目の数が正しいかチェック
          var notEQitemcnt = function( item1, item2, cal ) {
            if ( checkHash[item1].length + cal != checkHash[item2].length ) {
              angular.forEach( [ item1, item2 ], function( val, i ) {
                angular.element('*[name=' + val + ']').each(function() {
                  elmSetValid( this, false );
                });
              });
              angular.element('#valerr').text('項目数が一致しません');
              angular.element('#confapplybtn').removeAttr('disabled');
              return true;
            }
            return false;
          };
          if ( notEQitemcnt( 'dates', 'start_hours', 0 ) ) {
            return;
          }
          if ( notEQitemcnt( 'dates', 'end_hours', 0 ) ) {
            return;
          }
          if ( notEQitemcnt( 'pg_status_vals', 'pg_status_color', 1) ) {
            return;
          }
          // 実行
          doJsonPost( $http, uriprefix + '/config/setting',
                      $.param($scope.conf), $uibModalInstance, $uibModal,
                      function() {} );
        };
      }
    ]
  );
})();  
// -- EOF --
