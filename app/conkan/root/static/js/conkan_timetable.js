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
    function() {
        var currentval = {
            regpgid : '', subno : '', pgid :   '', id :      '', target : '',
            sname :   '', name :  '', stat :   '',
            date1 :   '', shour1 :  '', smin1 : '', ehour1 : '', emin1 :  '',
            date2 :   '', shour2 :  '', smin2 : '', ehour2 : '', emin2 :  '',
            roomid :  ''
        };
        return {
            current: currentval,
            query:   function(pgid) {
                // pgidの企画情報を取得し、currentvalに設定
                // subnoは前後に()付ける
            }
        };
    }
);

// タイムテーブルコントローラ
ConkanAppModule.controller( 'timetableController',
    [ '$scope', '$log', 'pglistValue',
        function( $scope, $log, pglistValue ) {
            $scope.ttgridbyroom = {
                enableFiltering: true,
                treeRowHeaderAlwaysVisible: false,
            };
            $scope.ttgridbyroom.columnDefs = [
                { name : 'room', grouping: { groupPriority: 1 },
                                 sort: { priority: 1, direction: 'asc' },  },
                { name : 'prgname' },
                { name : 'doperiod' },
            ];
            $scope.ttgridbyroom.data = pglistValue.roomprglist;

            $scope.ttgridbycast= {
                enableFiltering: true,
                treeRowHeaderAlwaysVisible: false,
            };
            $scope.ttgridbycast.columnDefs = [
                { name : 'cast', grouping: { groupPriority: 1 },
                                 sort: { priority: 1, direction: 'asc' },  },
                { name : 'prgname',
                                 sort: { priority: 2, direction: 'asc' },  },
                { name : 'room' },
                { name : 'doperiod' },
            ];
            $scope.ttgridbycast.data = pglistValue.castprglist;

            $scope.showbyroom = function( ) {
                $("#timetable_room").css( 'visibility', 'visible');
                $("#timetable_cast").css( 'visibility', 'hidden');
            };
            $scope.showbycast = function( ) {
                $("#timetable_room").css( 'visibility', 'hidden');
                $("#timetable_cast").css( 'visibility', 'visible');
            };
        }
    ]
);

// 未設定企画リストコントローラ
ConkanAppModule.controller( 'unsetlistController',
    [ '$scope', '$log', 'currentprgService', 'pglistValue',
        function( $scope, $log, currentprgService, pglistValue ) {
            $scope.unsetprglist = pglistValue.unsetprglist;
            $scope.unsetclick = function( pgid ) {
                $log.log( pgid );
            };
        }
    ]
);

// 設定フォームコントローラ
ConkanAppModule.controller( 'timeformController',
    [ '$scope', 'currentprgService', 'selectValue',
        function( $scope, currentprgService, selectValue ) {
            $scope.statuslist   = selectValue.statuslist;
            $scope.dateslist    = selectValue.dateslist;
            $scope.shourslist   = selectValue.shourslist;
            $scope.minslist     = selectValue.minslist;
            $scope.ehourslist   = selectValue.ehourslist;
            $scope.roomlist     = selectValue.roomlist;
            $scope.doApply = function() {
                $log.log( selectValue.statuslist ); 
                $log.log( selectValue.dateslist );
                $log.log( selectValue.shourslist );
                $log.log( selectValue.minslist );
                $log.log( selectValue.ehourslist );
                $log.log( selectValue.roomlist );
            };
          }
    ]
);

