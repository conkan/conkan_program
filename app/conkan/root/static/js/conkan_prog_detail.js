// conkan_prog_detail.js --- 企画詳細表示用 JS ---
/*esLint-env jquery, prototypejs */
(function() {
  // スクロール制御
  angular.element('.subtag a').click(function(){
    var 
      targ = angular.element(this.hash),
      wrap = targ.parent(),
      tp = targ.position().top,
      pd = parseInt(angular.element(document.body).css('padding-top')),
      sd = wrap.scrollTop(),
      pp = sd+tp-pd;
    wrap.scrollTop(pp);
    return false;
  });

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
        // 固定値設定
        var init_regpgid = angular.element('#init_regpgid').val();
        var init_pgid    = angular.element('#init_pgid').val();
        var init_subno   = angular.element('#init_subno').val();
        var init_name    = angular.element('#init_name').val();
        $scope.progress = {
          regpgid : init_regpgid,
          pgid    : init_pgid
        };
      // 表示データ取得メソッド群
        // 予定出演者リスト取得
        $scope.getRegCast = function () {
          $http({
            method  : 'GET',
            headers : { 'If-Modifired-Since' : (new Date(0)).toUTCString() },
            url     : uriprefix + '/program/' + init_pgid + '/regcastlist'
          })
          .success(function(data) {
            if ( data.status === 'ok' ) {
              $scope.regcastlist = data.json;
            }
            else {
              openDialog( data.status );
            }
          })
          .error( function() { httpfailDlg( $uibModal ); } );
        };
        // 決定出演者リスト取得
        $scope.getCast = function() {
          $http({
            method  : 'GET',
            headers : { 'If-Modifired-Since' : (new Date(0)).toUTCString() },
            url     : uriprefix + '/program/' + init_pgid + '/castlist'
          })
          .success(function(data) {
            if ( data.status === 'ok' ) {
              $scope.castlist = data.json;
              for ( var i=0; i<$scope.castlist.length; i++ ) {
                var cast = $scope.castlist[i];
                if (   ( cast.status == '企画不参加' )
                    || ( cast.status == '大会不参加' )
                    || ( cast.status == '欠席' )
                    || ( cast.status == '企画中止' )
                   ) {
                  cast.class = 'rmcast';
                }
                else {
                  cast.class = 'cast';
                }
              }
            }
            else {
              openDialog( data.status );
            }
          })
          .error( function() { httpfailDlg( $uibModal ); } );
        }; 
        // 決定機材リスト取得
        $scope.getEquip = function() {
          $http({
            method  : 'GET',
            headers : { 'If-Modifired-Since' : (new Date(0)).toUTCString() },
            url     : uriprefix + '/program/' + init_pgid + '/equiplist'
          })
          .success(function(data) {
            if ( data.status === 'ok' ) {
              $scope.equiplist = data.json;
              for ( var i=0; i<$scope.equiplist.length; i++ ) {
                var equip = $scope.equiplist[i];
                if (   ( equip.equipno == 'bring-AV' )
                    || ( equip.equipno == 'bring-PC' ) ) {
                  $scope.equiplist[i].spec = '映像:' + equip.vif
                                           + ' 音声:' + equip.aif;
                  if ( equip.equipno == 'bring-PC' ) {
                    $scope.equiplist[i].spec += ' LAN:' + equip.eif
                                             + ' LAN利用目的:' + equip.intende;
                  }
                }
              }
            }
            else {
              openDialog( data.status );
            }
          })
          .error( function() { httpfailDlg( $uibModal ); } );
        };

      // ダイアログ表示メソッド群
        // 企画要望更新ダイアログ
        $scope.openRegPgEditForm = function() {
          $uibModal.open({
            templateUrl : 'T_pgup_regprog',
            controller  : 'regProgFormController',
            backdrop    : 'static',
            scope       : $scope,
            size        : 'lg',
            resolve     :
              { params: function() {
                return {
                  pgid    : init_pgid
                };
              }},
          });
        };

        // 企画更新ダイアログ
        $scope.openPgEditForm = function() {
          $uibModal.open({
            templateUrl : 'T_pgup_program',
            controller  : 'progFormController',
            backdrop    : 'static',
            scope       : $scope,
            size        : 'lg',
            resolve     :
              { params: function() {
                return {
                  pgid    : init_pgid
                };
              }},
          });
        };

        // 予定出演者追加ダイアログ
        $scope.openRegCastForm = function() {
          $uibModal.open({
            templateUrl : 'T_pgup_regcast',
            controller  : 'regcastFormController',
            backdrop    : 'static',
            scope       : $scope,
            size        : 'lg',
            resolve     :
              { params: function() {
                return {
                  regpgid : init_regpgid,
                  subno   : init_subno,
                  pgid    : init_pgid,
                  name    : init_name,
                };
              }},
          });
        };

        // 決定出演者更新追加ダイアログ
        $scope.openCastEditForm = function( castid ) {
          $uibModal.open({
            templateUrl : 'T_pgup_cast',
            controller  : 'castFormController',
            backdrop    : 'static',
            scope       : $scope,
            size        : 'lg',
            resolve     :
              { params: function() {
                return {
                  regpgid : init_regpgid,
                  subno   : init_subno,
                  pgid    : init_pgid,
                  name    : init_name,
                  editCastId : castid,
                  editCastBtnLbl : ( castid === 0 ) ? '追加' : '更新',
                };
              }},
          });
        };

        // 決定機材更新追加ダイアログ
        $scope.openEquipForm = function( equipid ) {
          $uibModal.open({
            templateUrl : 'T_pgup_equip',
            controller  : 'equipFormController',
            backdrop    : 'static',
            scope       : $scope,
            size        : 'lg',
            resolve     :
              { params: function() {
                return {
                  regpgid : init_regpgid,
                  subno   : init_subno,
                  pgid    : init_pgid,
                  name    : init_name,
                  editEquipId : equipid,
                  editEquipBtnLbl : ( equipid === 0 ) ? '追加' : '更新',
                };
              }},
          });
        };

      // 埋め込みFormSubmitメソッド群
        // 進捗再表示
        $scope.progReload = function() {
          $scope.progress.progress = undefined;
          // 子コントローラのscopeは参照できないので、メッセージで実現
          $scope.$broadcast('PglRelEvent', 1);
        };
        // 進捗登録
        $scope.progDoAdd = function() {
          if ( !$scope.progress.progress || $scope.progress.progress == '' ) {
            return;
          }
          doJsonPost( $http, uriprefix + '/program/progress',
            $.param($scope.progress), undefined, $uibModal,
            function() {
              $scope.progReload(); // 登録した進捗を表示
            }
          );
        };

        // 初期値設定
        $scope.getRegCast();
        $scope.getCast();
        $scope.getEquip();
      }
    ]
  );

  // 企画要望更新ダイアログコントローラ
  ConkanAppModule.controller( 'regProgFormController',
    [ '$scope', '$http', '$uibModal', '$uibModalInstance', 'params',
      function( $scope, $http, $uibModal, $uibModalInstance, params ) {
        // 初期値設定
        angular.element('#valerr').text('');
        $http({
          method  : 'GET',
          url     : uriprefix + '/program/' + params.pgid + '/regprogram'
        })
        .success(function(data) {
          if ( data.status === 'ok' ) {
            $scope.prog = {
              pgid        : data.json.pgid,
              regpgid     : parseInt(data.json.regpgid),
              subno       : data.json.subno,
              name        : data.json.name,
              namef       : data.json.namef,
              regma       : data.json.regma,
              regname     : data.json.regname,
              regdate     : data.json.regdate,
              experience  : data.json.experience,
              regno       : data.json.regno,
              telno       : data.json.telno,
              faxno       : data.json.faxno,
              celno       : data.json.celno,
              type        : data.json.type,
              place       : data.json.place,
              layout      : data.json.layout,
              date        : data.json.date,
              classlen    : data.json.classlen,
              expmaxcnt   : data.json.expmaxcnt,
              content     : data.json.content,
              contentpub  : data.json.contentpub,
              realpub     : data.json.realpub,
              afterpub    : data.json.afterpub,
              openpg      : data.json.openpg,
              restpg      : data.json.restpg,
              avoiddup    : data.json.avoiddup,
              comment     : data.json.comment
            };
          }
          else {
            openDialog( data.status );
          }
        })
        .error( function() { httpfailDlg( $uibModal); } )
        .finally( dialogResizeDrag );

        // 更新実施
        $scope.regprgDoApply = function() {
          var pgid = $scope.prog.pgid;
          // 二重クリック回避
          angular.element('#regprgapplybtn').attr('disabled', 'disabled');
          doJsonPost( $http, uriprefix + '/program/' + pgid + '/regprogram',
            $.param($scope.prog), $uibModalInstance, $uibModal );
        };
      }
    ]
  );

  // 企画更新ダイアログコントローラ
  ConkanAppModule.controller( 'progFormController',
    [ '$scope', '$http', '$uibModal', '$uibModalInstance', 'params',
      function( $scope, $http, $uibModal, $uibModalInstance, params ) {
        // 選択肢取得
        $http.get(uriprefix + '/config/confget')
        .success(function(data) {
          if ( data.status === 'ok' ) {
            $scope.conf = ConfDataCnv( data, $scope.conf );
          }
          else {
            openDialog( data.status );
          }
        })
        .error( function() { httpfailDlg( $uibModal ); } );

        // 初期値設定
        angular.element('#valerr').text('');
        $http({
          method  : 'GET',
          url     : uriprefix + '/timetable/' + params.pgid
        })
        .success(function(data) {
          if ( data.status === 'ok' ) {
            $scope.prog = {};
            ProgDataCnv( data.json, $scope.prog );
          }
          else {
            openDialog( data.status );
          }
        })
        .error( function() { httpfailDlg( $uibModal); } )
        .finally( dialogResizeDrag );

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
          doJsonPost( $http, uriprefix + '/timetable/' + pgid,
            $.param($scope.prog), $uibModalInstance, $uibModal );
        };
      }
    ]
  );

  // 予定出演者追加ダイアログコントローラ
  ConkanAppModule.controller( 'regcastFormController',
    [ '$scope', '$http', '$uibModal', '$uibModalInstance', 'params',
      function( $scope, $http, $uibModal, $uibModalInstance, params ) {
        // 初期値設定
        angular.element('#valerr').text('');
        $scope.regcast = {
          regpgid   : params.regpgid,
          pgid      : params.pgid,
          name      : '', namef : '', regno : '',
          title : '', needreq : '', needguest : '',
        };
        $scope.prog = params;
        // 選択肢取得
        $http.get(uriprefix + '/config/confget')
        .success(function(data) {
          if ( data.status === 'ok' ) {
            $scope.conf = ConfDataCnv( data, $scope.conf );
          }
          else {
            openDialog( data.status );
          }
        })
        .error( function() { httpfailDlg( $uibModal ); } )
        .finally( dialogResizeDrag );

        // 登録実施
        $scope.regcastdoApply = function() {
          // 二重クリック回避
          angular.element('#regcastapplybtn').attr('disabled', 'disabled');
          doJsonPost( $http, uriprefix + '/program/regcastadd',
            $.param($scope.regcast), $uibModalInstance, $uibModal,
            function() {
              $scope.getRegCast();
              $scope.getCast();
              $scope.progReload(); // 更新した進捗を表示
            } );
        };
      }
    ]
  );

  // 決定出演者編集ダイアログコントローラ
  ConkanAppModule.controller( 'castFormController',
    [ '$scope', '$http', '$uibModal', '$uibModalInstance', 'params',
      function( $scope, $http, $uibModal, $uibModalInstance, params ) {
        // 初期値設定
        angular.element('#valerr').text('');
        $scope.prog = params;
        $http({
          method  : 'GET',
          url     : uriprefix + '/program/' + params.pgid + '/cast/' + params.editCastId,
        })
        .success(function(data) {
          if ( data.status === 'ok' ) {
            $scope.cast = {
              id          : params.editCastId,
              applyBtnLbl : params.editCastBtnLbl,
              pgid        : data.json.pgid,
              castid      : data.json.castid,
              status      : data.json.status,
              memo        : data.json.memo,
              name        : data.json.name,
              namef       : data.json.namef,
              title       : data.json.title,
            };
            $scope.castlist = data.json.castlist;
            $scope.statlist = data.json.statlist;
          }
          else {
            openDialog( data.status );
          }
        })
        .error( function() { httpfailDlg( $uibModal ); } )
        .finally( dialogResizeDrag );

        // 監視設定
        $scope.$watch('cast.castid', function( n, o, scope ) {
          if ( angular.isDefined(n) && angular.isDefined(o) ) {
            scope.cast.status = undefined;
            scope.cast.memo   = '';
            scope.cast.name   = '';
            scope.cast.namef  = '';
            scope.cast.title  = '';
          }
        });
        // 登録実施
        $scope.castdoApply = function() {
          var pgid   = $scope.cast.pgid;
          var itemid = $scope.cast.id;
          // 二重クリック回避
          angular.element('#castapplybtn').attr('disabled', 'disabled');
          angular.element('#castdelbtn').attr('disabled', 'disabled');
          // 実行
          doJsonPost( $http, uriprefix + '/program/' + pgid + '/cast/' + itemid,
            $.param($scope.cast), $uibModalInstance, $uibModal,
            function() {
              $scope.getCast();
              $scope.progReload(); // 更新した進捗を表示
            } );
        };
        // 削除実施
        $scope.castDoDel = function() {
          var pgid   = $scope.cast.pgid;
          var itemid = $scope.cast.id;
          // 二重クリック回避
          angular.element('#castapplybtn').attr('disabled', 'disabled');
          angular.element('#castdelbtn').attr('disabled', 'disabled');
          doJsonPost( $http, uriprefix + '/program/' + pgid + '/cast/' + itemid + '/del/',
            undefined, $uibModalInstance, $uibModal,
            function() {
              $scope.getCast();
              $scope.progReload(); // 更新した進捗を表示
            } );
        };
      }
    ]
  );

  var a2h = function(a,h) {
    for ( var i=0; i<a.length; i++ ) {
      h[a[i]] = 1;
    };
  };
  var IfOptions = {
    'avvif' : [ 'HDMI', 'S-Video', 'RCAコンポジット(黄)', 'その他', '未定' ],
    'pcvif' : [ '接続しない', 'HDMI', 'D-Sub15(VGA)', 'その他', '未定' ],
    'aif'   : [ '不要', 'ステレオミニ(3.5mmTSR)', 'RCAコンポジット(赤白)', 'その他', '未定' ],
    'eif'   : [ '接続しない', '有線(RJ-45)', '無線', 'その他', '未定' ],
    'vifH'  : {},
    'aifH'  : {},
    'eifH'  : {}
  };
  a2h( IfOptions.avvif.concat(IfOptions.pcvif).concat([undefined]), IfOptions.vifH );
  a2h( IfOptions.aif.concat([undefined]), IfOptions.aifH );
  a2h( IfOptions.eif.concat([undefined]), IfOptions.eifH );

  // 決定機材更新追加ダイアログコントローラ
  ConkanAppModule.controller( 'equipFormController',
    [ '$scope', '$http', '$uibModal', '$uibModalInstance', 'params',
      function( $scope, $http, $uibModal, $uibModalInstance, params ) {
        // 初期値設定
        angular.element('#valerr').text('');
        $scope.prog = params;
        $http({
          method  : 'GET',
          url     : uriprefix + '/program/' + params.pgid + '/equip/' + params.editEquipId,
        })
        .success(function(data) {
          if ( data.status === 'ok' ) {
            $scope.equip = {
              id            : params.editEquipId,
              applyBtnLbl   : params.editEquipBtnLbl,
              pgid    : data.json.pgid,
              equipid : data.json.equipid,
              intende : data.json.intende,
              spec    : '',
              comment : '',
            };
            if ( data.json.vif in IfOptions.vifH ) {
              $scope.equip.vif = data.json.vif;
            }
            else {
              $scope.equip.vif = 'その他';
              $scope.equip.ovif = data.json.vif;
            }
            if ( data.json.aif in IfOptions.aifH ) {
              $scope.equip.aif = data.json.aif;
            }
            else {
              $scope.equip.aif = 'その他';
              $scope.equip.oaif = data.json.aif;
            }
            if ( data.json.eif in IfOptions.eifH ) {
              $scope.equip.eif = data.json.eif;
            }
            else {
              $scope.equip.eif = 'その他';
              $scope.equip.oeif = data.json.eif;
            }
            $scope.equiplist = data.json.equiplist;
            $scope.equipdata = data.json.equipdata;
            $scope.bringid   = data.json.bringid;
            $scope.avviflist = IfOptions.avvif;
            $scope.pcviflist = IfOptions.pcvif;
            $scope.aiflist   = IfOptions.aif;
            $scope.eiflist   = IfOptions.eif;
          }
          else {
            openDialog( data.status );
          }
        })
        .error( function() { httpfailDlg( $uibModal ); } )
        .finally( dialogResizeDrag);

        // 監視設定
        $scope.$watch('equip.equipid', function( n, o, scope ) {
          if ( angular.isDefined(n) ) {
            if ( scope.bringid[n] ) {
              scope.eqtype = scope.bringid[n];
            }
            else {
              scope.eqtype = 'served';
              scope.equip.spec    = scope.equipdata[n].spec;
              scope.equip.comment = scope.equipdata[n].comment;
            }
          }
        });
        // 更新実施
        $scope.equipDoApply = function() {
          var pgid   = $scope.equip.pgid;
          var itemid = $scope.equip.id;
          // 二重クリック回避
          angular.element('#equipapplybtn').attr('disabled', 'disabled');
          angular.element('#equipdelbtn').attr('disabled', 'disabled');
          // その他 の内容置き換え
          if ( $scope.equip.vif == 'その他' ) {
            $scope.equip.vif = $scope.equip.ovif;
          }
          if ( $scope.equip.aif == 'その他' ) {
            $scope.equip.aif = $scope.equip.oaif;
          }
          if ( $scope.equip.eif == 'その他' ) {
            $scope.equip.eif = $scope.equip.oeif;
          }
          // 実行
          doJsonPost( $http, uriprefix + '/program/' + pgid + '/equip/' + itemid,
            $.param($scope.equip), $uibModalInstance, $uibModal,
            function() {
              $scope.getEquip();
              $scope.progReload(); // 更新した進捗を表示
            } );
        };
        // 削除実施
        $scope.equipDoDel = function() {
          var pgid   = $scope.equip.pgid;
          var itemid = $scope.equip.id;
          // 二重クリック回避
          angular.element('#equipapplybtn').attr('disabled', 'disabled');
          angular.element('#equipdelbtn').attr('disabled', 'disabled');
          doJsonPost( $http, uriprefix + '/program/' + pgid + '/equip/' + itemid + '/del/',
            undefined, $uibModalInstance, $uibModal,
            function() {
              $scope.getEquip();
              $scope.progReload(); // 更新した進捗を表示
            } );
        };
      }
    ]
  );

  // 進捗表示グリッドコントローラ
  ConkanAppModule.controller( 'progressListController',
    [ '$scope', '$http', '$uibModal', 'uiGridConstants',
      function( $scope, $http, $uibModal, uiGridConstants ) {
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
            width: '17%',
            cellClass: 'ui-grid-vcenter',
            enableHiding: false,
          },
          { name : '報告者', field : 'tname',
            headerCellClass: 'gridheader',
            width: '17%',
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
          var pgid    = angular.element('#init_pgid').val();
          var url = uriprefix + '/program/' + pgid + '/progress/'
                      + newPage + '/' + pageSize + '/';
          $http( {
            method  : 'GET',
            headers : { 'If-Modifired-Since' : (new Date(0)).toUTCString() },
            url     : url
          } )
          .success(function(data) {
            if ( data.status === 'ok' ) {
              $scope.progressgrid.totalItems = data.totalItems;
              $scope.progressgrid.data = data.json;
            }
            else {
              openDialog( data.status );
            }
          })
          .error( function() { httpfailDlg( $uibModal ); } );
        };
        // 親からのメッセージでリスト更新
        $scope.$on('PglRelEvent', function( ev, dt ) {
          getPage(dt);
        });

        getPage(1);
      }
    ]
  );

  // 企画選択ツールコントローラー
  ConkanAppModule.controller( 'pglistselController',
    [ '$scope', '$http', '$uibModal',
      function( $scope, $http, $uibModal ) {
        var pathelm = location.pathname.split('/');
        var allprg = pathelm[1] == 'mypage' ? false : true;
        var pgid = pathelm[pathelm.length-1];
        // 値設定
        $scope.pgsellist = [];
        $http({
          method  : 'GET',
          url     : uriprefix + '/program/listget' + ( allprg ? '_a' : '_r' ),
        })
        .success(function(data) {
          if ( data.status === 'ok' ) {
            for ( var i=0; i<data.json.length; i++ ) {
              var name = data.json[i].regpgid + ':';
              name += data.json[i].sname || data.json[i].name;
              if(name.length > 20) {
                name = name.substring(0, 19) + '...';
              }
              $scope.pgsellist[i] = {
                'id'  : data.json[i].pgid,
                'val' : name,
              };
            }
            $scope.pgdetailsel = pgid;
          }
          else {
            openDialog( data.status );
          }
        })
        .error( function () { httpfailDlg( $uibModal ); } );
        $scope.$watch('pgdetailsel', function( n, o, scope ) {
          if ( angular.isDefined(n) && angular.isDefined(o) && ( n != o ) ){
            pathelm[pathelm.length-1] = n;
            location.pathname = pathelm.join('/');
          }
        });
      }
    ]
  );
})();
// -- EOF --
