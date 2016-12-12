// conkan_profile.js --- プロファイル編集 JS ---
/*esLint-env jquery, prototypejs */
(function() {
  // conkanProfileモジュールの生成
  var ConkanAppModule = angular.module('conkanProfile',
    ['ui.grid', 'ui.grid.resizeColumns', 'ui.bootstrap'] );

  // プロファイルコントローラ
  ConkanAppModule.controller( 'profileController',
    [ '$scope', '$sce', '$http', '$uibModal',
      function( $scope, $sce, $http, $uibModal ) {

        var roleTable = { // 毎回動的に作成するのは効率が悪いので手書き
          'NORM'  : '企画スタッフ',
          'PG'    : '企画管理スタッフ',
          'ROOT'  : 'システム管理者'
        };
        var rolelist = [  // 毎回動的に作成するのは効率が悪いので手書き
          { 'id' : 'NORM', 'val' : '企画スタッフ' },
          { 'id' : 'PG',   'val' : '企画管理スタッフ' },
          { 'id' : 'ROOT', 'val' : 'システム管理者' }
        ];

        // roleを文字に変換
        $scope.__getRole = function( role ) {
          return $sce.trustAsHtml( roleTable[role] );
        };

        // ダイアログから兄弟コントローラのscopeは参照できないので、
        // 親コントローラが受け取ってメッセージで実現
        $scope.firePrfRel = function() {
          $scope.$broadcast('PrfRelEvent');
        };

        // プロファイルダイアログ
        $scope.openProfForm = function( staffid ) {
          $uibModal.open({
            templateUrl : 'T_prof_input',
            controller  : 'profFormController',
            backdrop    : 'static',
            scope       : $scope,
            size        : 'lg',
            resolve     :
              { params: function() {
                return {
                  editStaffId : staffid,
                  rolelist    : rolelist,
                };
              }},
          });
        };
      }
    ]
  );

  // プロファイルダイアログコントローラ
  ConkanAppModule.controller( 'profFormController',
    [ '$scope', '$http', '$uibModal', '$uibModalInstance', 'params',
      function( $scope, $http, $uibModal, $uibModalInstance, params ) {
        // 初期値設定
        angular.element('#valerr').text('');
        $http({
          method  : 'GET',
          url     : uriprefix + '/config/staff/' + params.editStaffId
        })
        .success(function(data) {
          if ( data.status === 'ok' ) {
            $scope.prof = {
              staffid       : data.json.staffid,
              cyid          : data.json.cyid,
              CybozuToken   : data.json.CybozuToken,
              CybozuSecret  : data.json.CybozuSecret,
              name          : data.json.name,
              account       : data.json.account,
              lastlogin     : data.json.lastlogin,
              role          : data.json.role,
              ma            : data.json.ma,
              telno         : data.json.telno,
              regno         : data.json.regno,
              tname         : data.json.tname,
              tnamef        : data.json.tnamef,
              comment       : data.json.comment,
            };
            $scope.rolelist = params.rolelist;
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
        $scope.profDoApply = function() {
          // 二重クリック回避
          angular.element('#profapplybtn').attr('disabled', 'disabled');
          angular.element('#profdelbtn').attr('disabled', 'disabled');
          // バリデーション
          elmSetValid( angular.element('*[name=passwd]'), true );
          elmSetValid( angular.element('*[name=passwd2]'), true );
          if ( $scope.prof.passwd != $scope.prof.passwd2 ) {
            angular.element('#valerr').text('パスワードが一致しません');
            elmSetValid( angular.element('*[name=passwd]'), false );
            elmSetValid( angular.element('*[name=passwd2]'), false );
            angular.element('#profapplybtn').removeAttr('disabled');
            return;
          }
          // 実行
          doJsonPost( $http, uriprefix + '/config/staff/' + $scope.prof.staffid + '/edit',
                      $.param($scope.prof), $uibModalInstance, $uibModal,
                      function() { $scope.firePrfRel(); } );
        };
        // 削除実施
        $scope.profDoDel = function() {
          // 二重クリック回避
          angular.element('#profapplybtn').attr('disabled', 'disabled');
          angular.element('#profdelbtn').attr('disabled', 'disabled');
          doJsonPost( $http, uriprefix + '/config/staff/' + $scope.prof.staffid + '/del',
                      undefined, $uibModalInstance, $uibModal,
                      function() { $scope.firePrfRel(); } );
        };
      }
    ]
  );
})();  
// -- EOF --
