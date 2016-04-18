$(window).resize(function() {
  // リサイズによるタイムテーブル領域の調整
  var
  h,w,gh,
  wh = window.innerHeight || $(window).innerHeight(),
  updiv     = $("#timetable_up"),
  downdiv   = $("#timetable_down"),
  unsetwrap = $("#unset_pglist_wrap"),
  timewrap  = $("#timetable_wrap"),
  viewport  = $("#timetable_wrap.ui-grid-viewport");
  h = wh - ( updiv.offset().top +
             downdiv.height()
           );
  updiv.css('height', h + 'px');
  updiv.css('max-height', h + 'px');
  updiv.css('min-height', h + 'px');
  unsetwrap.css('height', h + 'px');
  unsetwrap.css('min-height', h + 'px');
  unsetwrap.css('max-height', h + 'px');
  timewrap.css('height', h + 'px');
  timewrap.css('min-height', h + 'px');
  timewrap.css('max-height', h + 'px');
  gh = h - ( $('#timetable_wrap>.row').height() +
             $('.ui-grid-render-container-right .ui-grid-header').height() +
             $('.ui-grid-scrollbar-placeholder').height() +
             1);
  viewport.css('height', gh + 'px');
  viewport.css('max-height', gh + 'px');
  viewport.css('min-height', gh + 'px');
  w = timewrap.width();
  $("#timetable_room").width(w);
  $("#timetable_cast").width(w);
});

// conkanTimeTableモジュールの取得(生成済のもの)
var ConkanAppModule = angular.module('conkanTimeTable' );

// 現在操作中企画サービス
ConkanAppModule.factory( 'currentprgService',
    function( $http ) {
        var currentval = {
                regpgid : '', subno :  '', pgid :  '',
                sname :   '', name :   '', status :  '',
                date1 :   '', shour1 : '', smin1 : '', ehour1 : '', emin1 : '',
                date2 :   '', shour2 : '', smin2 : '', ehour2 : '', emin2 : '',
                roomid :  ''
        };
        return {
            currentval: currentval,
            query:   function(pgid) {
                $('#valerr').text('');
                $('#dh1').css('background-color', '');
                $('#dh2').css('background-color', '');
                $http({
                    method  : 'GET',
                    url     : '/timetable/' + pgid
                }).success(function(data, status, headers, config) {
                    // pgidの企画情報を取得し、currentvalに設定
                    // subnoは前後に()付ける
                    currentval.regpgid = data.regpgid;
                    currentval.subno   = '(' + data.subno + ')';
                    currentval.pgid    = data.pgid;
                    currentval.sname   = data.sname;
                    currentval.name    = data.name;
                    currentval.status  = data.status;
                    currentval.date1   = data.date1;
                    currentval.shour1  = data.shour1;
                    currentval.smin1   = data.smin1;
                    currentval.ehour1  = data.ehour1;
                    currentval.emin1   = data.emin1;
                    currentval.date2   = data.date2;
                    currentval.shour2  = data.shour2;
                    currentval.smin2   = data.smin2;
                    currentval.ehour2  = data.ehour2;
                    currentval.emin2   = data.emin2;
                    currentval.roomid  = data.roomid;
                });
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
    [ '$scope', 'uiGridConstants', 'currentprgService', 'pglistValue', '$sce',
        function( $scope, uiGridConstants, currentprgService, pglistValue, $sce ) {
            $scope.__getGanttWidth = function() {
                var colmnum = pglistValue.ganttConst.maxcolmnum + 1;
                return pglistValue.ganttConst.cell_width * colmnum;
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
                    cellTemplate: '<div ng-if="!row.groupHeader"><button class="btn primary prgcell" ng-click=grid.appScope.pgmclick(row.entity.prgname.pgid)>{{row.entity.prgname.name}}</button></div>'
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
                    cellTemplate: '<div ng-if="!row.groupHeader"><button class="btn primary prgcell" ng-click=grid.appScope.pgmclick(row.entity.prgname.pgid)>{{row.entity.prgname.name}}</button></div>'
                },
                { name : '部屋', field: 'room',
                    headerCellClass: 'gridheader',
                    cellTemplate: '<div ng-if="!row.groupHeader">{{COL_FIELD CUSTOM_FILTERS}}</div>'
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
    [ '$scope', '$http', '$uibModal', 'currentprgService', 'selectValue',
        function( $scope, $http, $uibModal, currentprgService, selectValue ) {
            $scope.statuslist   = selectValue.statuslist;
            $scope.dateslist    = selectValue.dateslist;
            $scope.shourslist   = selectValue.shourslist;
            $scope.minslist     = selectValue.minslist;
            $scope.ehourslist   = selectValue.ehourslist;
            $scope.roomlist     = selectValue.roomlist;
            $scope.current      = currentprgService.currentval;
            var scale_hash = selectValue.scale_hash;
            $scope.doApply = function() {
                var ckarray, cnt, cur, scale, start, end;
                var pgid = $scope.current.pgid;
                // バリデーション
                if (!(pgid)) {
                    return;
                }
                ckarray = [
                    {
                        dh    : '#dh1',
                        date  : $scope.current.date1,
                        shour : $scope.current.shour1,
                        smin  : $scope.current.smin1,
                        ehour : $scope.current.ehour1,
                        emin  : $scope.current.emin1
                    },
                    {
                        dh    : '#dh2',
                        date  : $scope.current.date2,
                        shour : $scope.current.shour2,
                        smin  : $scope.current.smin2,
                        ehour : $scope.current.ehour2,
                        emin  : $scope.current.emin2
                    }
                ];
                for ( cnt in ckarray ) {
                    if ( ckarray[cnt].date ) {
                        cur = ckarray[cnt];
                        scale = scale_hash[cur.date];
                        start = ( cur.shour * 60 ) + ( cur.smin * 1 );
                        end   = ( cur.ehour * 60 ) + ( cur.emin * 1 );
                        if (   ( start >= end )
                            || ( start < scale[0] ) || ( scale[1] < end ) ) {
                            $('#valerr').text('時刻設定に矛盾があります');
                            $(cur.dh).css('background-color', '#ff8e8e');
                            return;
                        }
                    }
                }
                $http( {
                    method : 'POST',
                    url : '/timetable/' + pgid,
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
                    data: $.param($scope.current)
                }).success(function(data, status, headers, config) {
                    var modalinstance, templateval;
                    if (data.status == 'update') {
                        templateval = 'T_result_update';
                    }
                    else {
                        templateval = 'T_result_fail';
                    }
                    modalinstance = $uibModal.open(
                        {
                            templateUrl : templateval,
                            backdrop    : 'static'
                        }
                    );
                    modalinstance.result.then( function() {
                        if (data.status == 'update') {
                            location.reload();
                        } else {
                            currentprgService.query( pgid );
                        }
                    });
                }).error(function(data, status, headers, config) {
                    var modalinstance = $uibModal.open(
                        {
                            templateUrl : 'T_result_dberr',
                            backdrop    : 'static'
                        }
                    );
                    modalinstance.result.then( function() {
                        currentprgService.query( pgid );
                    });
                });
            };
          }
    ]
);

// -- EOF --
