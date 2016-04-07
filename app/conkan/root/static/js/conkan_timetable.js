$(window).resize(function() {
  // リサイズによるタイムテーブル領域の調整
  var
  h,w,
  wh = window.innerHeight || $(window).innerHeight(),
  updiv   = $("#timetable_up"),
  downdiv = $("#timetable_down");
  h = wh - ( updiv.offset().top +
             downdiv.outerHeight() +
             parseFloat(downdiv.css('marginTop'))
           );
  updiv.css('height', h + 'px');
  updiv.css('max-height', h + 'px');
  $("#unset_pglist_wrap").css('min-height', h + 'px');
  $("#timetable_wrap").css('min-height', h + 'px');
  w = $("#timetable_wrap").width();
  $("#timetable_room").width(w);
  $("#timetable_cast").width(w);
});

// conkanTimeTableモジュールの取得(生成済のもの)
var ConkanAppModule = angular.module('conkanTimeTable' );

// 現在操作中企画サービス
ConkanAppModule.factory( 'currentprgService',
    function( $log ) {
        return {
            currentval: {
                regpgid : '', subno :  '', pgid :  '', id : '', target : '',
                sname :   '', name :   '', stat :  '',
                date1 :   '', shour1 : '', smin1 : '', ehour1 : '', emin1 : '',
                date2 :   '', shour2 : '', smin2 : '', ehour2 : '', emin2 : '',
                roomid :  ''
            },
            query:   function(pgid) {
                $log.log( pgid );
                // pgidの企画情報を取得し、currentvalに設定
                // subnoは前後に()付ける
            }
        };
    }
);

// 未設定企画リストコントローラ
ConkanAppModule.controller( 'unsetlistController',
    [ '$scope', 'currentprgService', 'pglistValue',
        function( $scope, currentprgService, pglistValue ) {
            $scope.unsetprglist = pglistValue.unsetprglist;
            $scope.unsetclick = function( pgid ) {
                currentprgService.query( pgid );
            };
        }
    ]
);

// タイムテーブルコントローラ
ConkanAppModule.controller( 'timetableController',
    [ '$scope', 'currentprgService', 'pglistValue', '$sce',
        function( $scope, currentprgService, pglistValue, $sce ) {
            $scope.__getGanttWidth = function() {
                return pglistValue.ganttConst.cell_width * ( pglistValue.ganttConst.colmnum + 1 );
            };
            $scope.__crGanttCell = function( doperiod ) {
                var retval = pglistValue.ganttConst.ganttBackGrid;
                retval += '<div class="ganttBar" style="left:10px;width:48px"></div>';
                var wkstr = $sce.trustAsHtml( retval );
                return wkstr;
            };

            $scope.ttgridbyroom = {
                enableFiltering: false,
                enableSorting: false,
                treeRowHeaderAlwaysVisible: false,
                enableColumnResizing: true,
                enableGridMenu: false
            };
            $scope.ttgridbyroom.columnDefs = [
                { name : '部屋', field: 'room',
                    headerCellClass: 'gridheader',
                    grouping: { groupPriority: 1 },
                    sort: { priority: 0, direction: 'asc' }
                },
                { name : '企画名', field: 'prgname',
                    headerCellClass: 'gridheader',
                    sort: { priority: 1, direction: 'asc' }, 
                    cellTemplate: '<button class="btn primary prgcell" ng-click=grid.appScope.pgmclick(row.entity.prgname.pgid)>{{row.entity.prgname.name}}</button>'
                },
                { name : '期間',
                    headerCellTemplate: pglistValue.ganttConst.ganttHeader,
                    field: 'doperiod',
                    pinnedRight:true,
                    width: $scope.__getGanttWidth(),
                    cellTooltip: true,
                    cellTemplate: '<div class="ganttRow ui-grid-cell-contents" title="TOOLTIP" ng-bind-html="grid.appScope.__crGanttCell(row.entity.doperiod)"></div>'
                }
            ];
            $scope.ttgridbyroom.data = pglistValue.roomprglist;

            $scope.ttgridbycast= {
                enableFiltering: false,
                enableSorting: false,
                treeRowHeaderAlwaysVisible: false,
                enableColumnResizing: true,
                enableGridMenu: false
            };
            $scope.ttgridbycast.columnDefs = [
                { name : '出演者', field: 'cast',
                    headerCellClass: 'gridheader',
                    grouping: { groupPriority: 1 },
                    sort: { priority: 0, direction: 'asc' }
                },
                { name : '企画名', field: 'prgname',
                    headerCellClass: 'gridheader',
                    sort: { priority: 1, direction: 'asc' },
                    cellTemplate: '<button class="btn primary prgcell" ng-click=grid.appScope.pgmclick(row.entity.prgname.pgid)>{{row.entity.prgname.name}}</button>'
                },
                { name : '部屋', field: 'room',
                    headerCellClass: 'gridheader'
                },
                { name : '期間',
                    headerCellTemplate: pglistValue.ganttConst.ganttHeader,
                    width: $scope.__getGanttWidth(),
                    field: 'doperiod',
                    pinnedRight:true,
                    cellTooltip: true,
                    cellTemplate: '<div class="ganttRow ui-grid-cell-contents" title="TOOLTIP" ng-bind-html="grid.appScope.__crGanttCell(row.entity.doperiod)"></div>'
                }
            ];
            $scope.ttgridbycast.data = pglistValue.castprglist;

            $scope.showbyroom = function( ) {
                $("#timetable_room").css( 'visibility', 'visible');
                $("#roombtn").addClass( 'showbtnon' );
                $("#timetable_cast").css( 'visibility', 'hidden');
                $("#castbtn").removeClass( 'showbtnon' );
            };
            $scope.showbycast = function( ) {
                $("#timetable_room").css( 'visibility', 'hidden');
                $("#roombtn").removeClass( 'showbtnon' );
                $("#timetable_cast").css( 'visibility', 'visible');
                $("#castbtn").addClass( 'showbtnon' );
            };
            $scope.pgmclick = function( pgid ) {
                currentprgService.query( pgid );
            };
        }
    ]
);

// 設定フォームコントローラ
ConkanAppModule.controller( 'timeformController',
    [ '$scope', '$log', 'currentprgService', 'selectValue',
        function( $scope, $log, currentprgService, selectValue ) {
            $scope.statuslist   = selectValue.statuslist;
            $scope.dateslist    = selectValue.dateslist;
            $scope.shourslist   = selectValue.shourslist;
            $scope.minslist     = selectValue.minslist;
            $scope.ehourslist   = selectValue.ehourslist;
            $scope.roomlist     = selectValue.roomlist;
            $scope.current      = currentprgService.currentval;
            $scope.doApply = function() {
                $log.log( currentprgService.currentval.regpgid );
                $log.log( currentprgService.currentval.subno );
                $log.log( currentprgService.currentval.pgid );
                $log.log( currentprgService.currentval.id );
                $log.log( currentprgService.currentval.target );
                $log.log( currentprgService.currentval.sname );
                $log.log( currentprgService.currentval.name );
                $log.log( currentprgService.currentval.stat );
                $log.log( currentprgService.currentval.date1 );
                $log.log( currentprgService.currentval.shour1 );
                $log.log( currentprgService.currentval.smin1 );
                $log.log( currentprgService.currentval.ehour1 );
                $log.log( currentprgService.currentval.emin1 );
                $log.log( currentprgService.currentval.date2 );
                $log.log( currentprgService.currentval.shour2 );
                $log.log( currentprgService.currentval.smin2 );
                $log.log( currentprgService.currentval.ehour2 );
                $log.log( currentprgService.currentval.emin2 );
                $log.log( currentprgService.currentval.roomid );
            };
          }
    ]
);

