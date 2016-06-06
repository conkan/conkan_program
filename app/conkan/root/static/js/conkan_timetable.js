// conkan_timetable.js --- タイムテーブル用 JS ---
/*esLint-env jquery, prototypejs */
(function() {
  // リサイズによるタイムテーブル領域の調整
  angular.element(window).resize(function() {
    var h,w,gh,
      wh = angular.element(window).innerHeight(),
      updiv     = angular.element("#timetable_up"),
      downdiv   = angular.element("#timetable_down"),
      unsetwrap = angular.element("#unset_pglist_wrap"),
      timewrap  = angular.element("#timetable_wrap"),
      footer = angular.element("#main-footer"),
      viewport  = angular.element("#timetable_wrap.ui-grid-viewport");
    h = wh - ( updiv.offset().top + downdiv.height() + footer.outerHeight() );
    updiv.css('height', h + 'px');
    updiv.css('max-height', h + 'px');
    updiv.css('min-height', h + 'px');
    unsetwrap.css('height', h + 'px');
    unsetwrap.css('min-height', h + 'px');
    unsetwrap.css('max-height', h + 'px');
    timewrap.css('height', h + 'px');
    timewrap.css('min-height', h + 'px');
    timewrap.css('max-height', h + 'px');
    gh = h - (
      angular.element('#timetable_wrap>.row').height()
      + angular.element('.ui-grid-render-container-right .ui-grid-header').height()
      + angular.element('.ui-grid-scrollbar-placeholder').height()
      + 1
    );
    viewport.css('height', gh + 'px');
    viewport.css('max-height', gh + 'px');
    viewport.css('min-height', gh + 'px');
    w = timewrap.width();
    angular.element("#timetable_room").width(w);
    angular.element("#timetable_cast").width(w);
  });

  // conkanTimeTableモジュールの取得(生成済のもの)
  var ConkanAppModule = angular.module('conkanTimeTable' );

  // 現在操作中企画サービス
  ConkanAppModule.factory( 'currentprgService',
    function( $http, $sce ) {
      var currentval = {
        regpgid : '', subno :  '', pgid :  '',
        sname :   '', name :   '', status :  '',
        date1 :   '', shour1 : '', smin1 : '', ehour1 : '', emin1 : '',
        date2 :   '', shour2 : '', smin2 : '', ehour2 : '', emin2 : '',
        roomid :  '', noteditable : true
      };
      return {
        currentval: currentval,
        query:   function(pgid) {
          angular.element('#valerr').text('');
          currentval.pgid = '';
          $http({ method  : 'GET', url     : '/timetable/' + pgid })
          .success(function(data) {
            if ( data.status === 'ok' ) {
              ProgDataCnv( data.json, currentval );
            }
            else {
              openDialog( data.status );
            }
          })
          .error( httpfailDlg );
        }
      };
    }
  );

  // 未設定企画リストコントローラ
  ConkanAppModule.controller( 'unsetlistController',
    [ '$scope', 'currentprgService', 'pglistValue',
      function( $scope, currentprgService, pglistValue ) {
        var color_hash = pglistValue.ganttConst.color_hash;
        $scope.unsetprglist = pglistValue.unsetprglist.map(function(p) {
          p.color = color_hash[p.status];
          return p;
        });
        $scope.unsetclick = function( pgid ) {
          currentprgService.query( pgid );
        };
      }
    ]
  );

  // タイムテーブルコントローラ
  ConkanAppModule.controller( 'timetableController',
    [ '$scope', 'uiGridConstants', 'currentprgService', 'pglistValue', '$sce',
      function( $scope, uiGridConstants, currentprgService, pglistValue, $sce ) {
        $scope.__getGanttWidth = function() {
          var colmnum = pglistValue.ganttConst.maxcolmnum + 1;
          return pglistValue.ganttConst.cell_width * colmnum;
        };
        $scope.__crPgBtn = function( name, status ) {
          var retval, wkstr;
          var color_hash = pglistValue.ganttConst.color_hash;
          if ( !name ) { // GroupHeaderの時呼ばれる
            return '';
          }
          retval = '<span style="background-color:'
            + color_hash[status] + ';">&nbsp;</span>'
            + name;
          wkstr = $sce.trustAsHtml( retval );
          return wkstr;
        };

        $scope.__crGanttCell = function( doperiod, status ) {
          var retval = pglistValue.ganttConst.ganttBackGrid;
          var scale_hash = pglistValue.ganttConst.scale_hash;
          var color_hash = pglistValue.ganttConst.color_hash;
          var color = color_hash[status];
          var unit = pglistValue.ganttConst.cell_width;
          var cnt, curscale, date, times, start, end, bias, width, wkstr;
          if ( !doperiod ) { // GroupHeaderの時呼ばれる
            return '';
          }
          var periodDatas = doperiod.split(" ");
          for ( cnt=0; cnt<periodDatas.length; cnt+=2 ) {
            date = periodDatas[cnt];
            curscale = scale_hash[date];
            times = periodDatas[cnt+1].split(/[:-]/);
            start = ( times[0] * 60 ) + ( times[1] * 1 );
            end   = ( times[2] * 60 ) + ( times[3] * 1 );
            bias  =  ( curscale[2] * unit )
              + ( ( ( start - curscale[0] ) * unit ) / 60 );
            width = ( ( end - start ) * unit ) / 60;
            retval += '<div class="ganttBar" style="left:'
                    + bias
                    + 'px;width:'
                    + width
                    + 'px;background-color:'
                    + color
                    + ';"></div>';
          }
          wkstr = $sce.trustAsHtml( retval );
          return wkstr;
        };

        $scope.ttgridbyroom = {
          enableFiltering: false,
          enableSorting: false,
          treeRowHeaderAlwaysVisible: false,
          enableColumnResizing: true,
          enableGridMenu: false,
          onRegisterApi: function(gridApi) {
            $scope.grRoomApi = gridApi;
            $scope.grRoomApi.grid.registerDataChangeCallback(function() {
              $scope.grRoomApi.treeBase.expandAllRows();
            });
          }
        };
        $scope.ttgridbyroom.columnDefs = [
          { name : '部屋', field: 'room',
            headerCellClass: 'gridheader',
            sort: { priority: 0, direction: uiGridConstants.ASC },
            grouping: { groupPriority: 0 },
            cellTemplate: '<div><div ng-if="!col.grouping || col.grouping.groupPriority === undefined || col.grouping.groupPriority === null || ( row.groupHeader && col.grouping.groupPriority === row.treeLevel )" class="ui-grid-cell-contents" title="TOOLTIP">{{COL_FIELD CUSTOM_FILTERS}}</div></div>'
          },
          { name : '企画名', field: 'prgname',
            headerCellClass: 'gridheader',
            sort: { priority: 1, direction: uiGridConstants.DSC },
            cellTooltip: true,
            cellTemplate: '<div ng-if="!row.groupHeader"><div class="ganttRow ui-grid-cell-contents" title="{{row.entity.status}}"><button class="btn primary prgcell" ng-click="grid.appScope.pgmclick(row.entity.prgname.pgid)"><div ng-bind-html="grid.appScope.__crPgBtn(row.entity.prgname.name, row.entity.status)"></div></button></div></div>'
          },
          { name : '期間',
            headerCellTemplate: pglistValue.ganttConst.ganttHeader,
            field: 'doperiod',
            pinnedRight:true,
            width: $scope.__getGanttWidth(),
            cellTooltip: true,
            cellTemplate: '<div ng-if="!row.groupHeader"><div class="ganttRow ui-grid-cell-contents" title="TOOLTIP" ng-bind-html="grid.appScope.__crGanttCell(row.entity.doperiod, row.entity.status)"></div></div>'
          }
        ];
        $scope.ttgridbyroom.data = pglistValue.roomprglist;

        $scope.ttgridbycast= {
          enableFiltering: false,
          enableSorting: false,
          treeRowHeaderAlwaysVisible: false,
          enableColumnResizing: true,
          enableGridMenu: false,
          onRegisterApi: function(gridApi) {
            $scope.grCastApi = gridApi;
            $scope.grCastApi.grid.registerDataChangeCallback(function() {
              $scope.grCastApi.treeBase.expandAllRows();
            });
          }
        };
        $scope.ttgridbycast.columnDefs = [
          { name : '出演者', field: 'cast',
            headerCellClass: 'gridheader',
            grouping: { groupPriority: 0 },
            sort: { priority: 0, direction: uiGridConstants.ASC },
            cellTemplate: '<div><div ng-if="!col.grouping || col.grouping.groupPriority === undefined || col.grouping.groupPriority === null || ( row.groupHeader && col.grouping.groupPriority === row.treeLevel )" class="ui-grid-cell-contents" title="TOOLTIP">{{COL_FIELD CUSTOM_FILTERS}}</div></div>'
          },
          { name : '企画名', field: 'prgname',
            headerCellClass: 'gridheader',
            sort: { priority: 1, direction: uiGridConstants.DSC },
            cellTooltip: true,
            cellTemplate: '<div ng-if="!row.groupHeader"><div class="ganttRow ui-grid-cell-contents" title="{{row.entity.status}}"><button class="btn primary prgcell" ng-click="grid.appScope.pgmclick(row.entity.prgname.pgid)"><div ng-bind-html="grid.appScope.__crPgBtn(row.entity.prgname.name, row.entity.status)"></div></button></div></div>'
          },
          { name : '期間',
            headerCellTemplate: pglistValue.ganttConst.ganttHeader,
            width: $scope.__getGanttWidth(),
            field: 'doperiod',
            pinnedRight:true,
            cellTooltip: true,
            cellTemplate: '<div ng-if="!row.groupHeader"><div class="ganttRow ui-grid-cell-contents" title="TOOLTIP" ng-bind-html="grid.appScope.__crGanttCell(row.entity.doperiod, row.entity.status)"></div></div>'
          }
        ];
        $scope.ttgridbycast.data = pglistValue.castprglist;

        $scope.showbyroom = function( ) {
          angular.element("#timetable_room").css( 'visibility', 'visible');
          angular.element("#roombtn").addClass( 'showbtnon' );
          angular.element("#timetable_cast").css( 'visibility', 'hidden');
          angular.element("#castbtn").removeClass( 'showbtnon' );
        };
        $scope.showbycast = function( ) {
          angular.element("#timetable_room").css( 'visibility', 'hidden');
          angular.element("#roombtn").removeClass( 'showbtnon' );
          angular.element("#timetable_cast").css( 'visibility', 'visible');
          angular.element("#castbtn").addClass( 'showbtnon' );
        };
        $scope.pgmclick = function( pgid ) {
          currentprgService.query( pgid );
        };
      }
    ]
  );

  // 設定フォームコントローラ
  ConkanAppModule.controller( 'timeformController',
    [ '$scope', '$http', '$uibModal', 'currentprgService',
      function( $scope, $http, $uibModal, currentprgService ) {
        $scope.$watch('current.date1', function( n, o, scope ) {
          if ( n != o ) {
            scope.conf['hours1'] = GetHours(n, scope.conf, scope.current, '1');
          }
        });

        $scope.$watch('current.date2', function( n, o, scope ) {
          if ( n != o ) {
            scope.conf['hours2'] = GetHours(n, scope.conf, scope.current, '2');
          }
        });

        $scope.$watch('current.pgid', function( n, o, scope ) {
          scope.timetable_edit_form.$setPristine();
        });

        $http.get('/config/confget')
        .success(function(data) {
          if ( data.status === 'ok' ) {
            $scope.conf = ConfDataCnv( data, $scope.conf );
          }
          else {
            openDialog( data.status );
          }
        })
        .error( httpfailDlg );

        $scope.current      = currentprgService.currentval;

        $scope.doApply = function() {
          var pgid = $scope.current.pgid;
          // 二重クリック回避
          angular.element('#applybtn').attr('disabled', 'disabled');
          // バリデーション
          if ( ProgTimeValid( $scope.current, $scope.conf.scale_hash ) ) {
            angular.element('#valerr').text('時刻設定に矛盾があります');
            angular.element('#applybtn').removeAttr('disabled');
            return;
          }
          $http( {
            method : 'POST',
            url : '/timetable/' + pgid,
            headers: { 'Content-Type':
                         'application/x-www-form-urlencoded; charset=UTF-8' },
            data: $.param($scope.current)
          })
          .success(function(data) {
            var resultDlg = $uibModal.open(
              {
                templateUrl : getTemplate( data.status ),
                backdrop    : 'static',
              }
            );
            resultDlg.rendered.then( function() {
              angular.element('.modal-dialog')
                .draggable({handle: '.modal-header'});
            });
            resultDlg.result.then( function() {
              if (data.status == 'update') {
                location.reload();
              }
              else {
                angular.element('#applybtn').removeAttr('disabled');
                currentprgService.query( pgid );
              }
            });
          })
          .error(function(data) {
            var resultDlg = $uibModal.open(
              {
                templateUrl : getTemplate( '' ),
                backdrop    : 'static',
              }
            );
            resultDlg.rendered.then( function() {
              angular.element('.modal-dialog')
                .draggable({handle: '.modal-header'});
            });
            resultDlg.result.then( function() {
              angular.element('#applybtn').removeAttr('disabled');
              currentprgService.query( pgid );
            });
          });
        };
      }
    ]
  );
})();
// -- EOF --
