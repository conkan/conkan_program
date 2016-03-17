$(window).resize(function() {
  // リサイズによるタイムテーブル領域の調整
  var
  h,
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
            }
        };
    }
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
          }
    ]
);

