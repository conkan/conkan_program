企画登録WebAPI
==============

1. conkan programにadminとしてlogin

METHOD  : POST
URL     : <Conkan_Program_URL>/login
POSTDATA: [  'realm'     => 'passwd',      // 固定値
             'account'   => 'admin',       // 固定値
             'passwd'    => ,              // 事前に共有
          ]

1. 企画情報を登録

METHOD  : POST
URL     : <Conkan_Program_URL>/program/add
POSTDATA: Content_Type => 'form-data',
          Content      =>
             [
                 'jsoninputfile' =>
                     [
                         undef,
                         'regprog.json',
                         'Content-Type' => 'application/octet-stream',
                         'Content'      => <パラメータ>
                     ]
             ]
<パラメータ>は、下記 javascript Object をJSON化した値
webAPI = {
    'WebAPI_VERSION'    :   '2.0',      // 固定値
    'regdate'           :   ,           // 申込日時
    'p1_name'           :   ,           // 申込者氏名                
    'email'             :   ,           // 申込者メールアドレス      
    'reg_num'           :   ,           // 申込者登録番号            
    'tel'               :   ,           // 申込者電話番号            
    'fax'               :   ,           // 申込者FAX番号             
    'cellphone'         :   ,           // 申込者携帯番号            
    'pg_name'           :   ,           // 企画名                    
    'pg_name_f'         :   ,           // 企画名フリガナ            
    'pg_kind'           :   ,           // 企画種別(その他内容)      
    'pg_place'          :   ,           // 希望場所(その他内容)      
    'pg_layout'         :   ,           // 希望レイアウト(その他内容)
    'pg_time'           :   ,           // 希望時刻(その他内容       
    'pg_koma'           :   ,           // 希望コマ数(その他内容)    
    'pg_ninzu'          :   ,           // 予想人数                  
    'pg_naiyou'         :   ,           // 企画内容                  
    'pg_naiyou_k'       :   ,           // 内容事前公開              
    'pg_kiroku_kb'      :   ,           // リアルタイム公開          
    'pg_kiroku_ka'      :   ,           // 事後公開                  
    'pg_pggen'          :   ,           // 一般公開可否              
    'pg_pgu18'          :   ,           // 未成年参加可否            
    'pg_badprog'        :   ,           // 重なると困る企画          
    'pg_enquete'        :   ,           // 企画経験                  
    'fc_comment'        :   ,           // 備考(連絡可能時間帯)      
    'equips'            :               // 機材情報配列
    [
        {
            'name'              :   ,       // 機材名
            'count'             :   ,       // 本数
            'vif'               :   ,       // 映像接続
            'aif'               :   ,       // 音声接続
            'eif'               :   ,       // LAN接続
            'intende'           :   ,       // LAN利用目的
        },
    ],
    'casts'             :               // 出演者情報配列
    [
        {
            'name'              :   ,       // 出演者登録名      
            'entrantregno'      :   ,       // 出演者登録番号    
            'pgname'            :   ,       // 企画ネーム        
            'pgnamef'           :   ,       // 企画ネームフリガナ
            'pgtitle'           :   ,       // 肩書              
            'needreq'           :   ,       // 出演交渉
            'needguest'         :   ,       // ゲスト申請
        },
    ],
}

1. 登録POSTのRESPONCEから、内部企画IDと企画IDを取り出す

RESPONCEは
    <a href="/program/{内部企画ID}&amp;prog_id={企画ID}">

1. logout

prog_regist上のパラメータとWebAPI JSONキーの関係表
=====

+------------------+---------------------------+----------------------------+
|Param名           | =>  JSONキー              | 説明                       |
+------------------+---------------------------+----------------------------+
|                  | => 'WebAPI_VERSION'       | WebAPIバージョン('2.0'固定)|
|'regdate'         | => 'regdate'              | 申込日時                   |
|'p1_name'         | => 'p1_name'              | 申込者氏名                 |
|'email'           | => 'email'                | 申込者メールアドレス       |
|'reg_num'         | => 'reg_num'              | 申込者登録番号             |
|'tel'             | => 'tel'                  | 申込者電話番号             |
|'fax'             | => 'fax'                  | 申込者FAX番号              |
|'cellphone'       | => 'cellphone'            | 申込者携帯番号             |
|'pg_name'         | => 'pg_name'              | 企画名                     |
|'pg_name_f'       | => 'pg_name_f'            | 企画名フリガナ             |
|'pg_kind'         | => 'pg_kind'              | 企画種別(その他内容)       |
|'pg_place'        | => 'pg_place'             | 希望場所(その他内容)       |
|'pg_layout'       | => 'pg_layout'            | 希望レイアウト(その他内容) |
|'pg_time'         | => 'pg_time'              | 希望時刻(その他内容        |
|'pg_koma'         | => 'pg_koma'              | 希望コマ数(その他内容)     |
|'pg_ninzu'        | => 'pg_ninzu'             | 予想人数                   |
|'pg_naiyou'       | => 'pg_naiyou'            | 企画内容                   |
|'pg_naiyou_k'     | => 'pg_naiyou_k'          | 内容事前公開               |
|'pg_kiroku_kb'    | => 'pg_kiroku_kb'         | リアルタイム公開           |
|'pg_kiroku_ka'    | => 'pg_kiroku_ka'         | 事後公開                   |
|'pg_pggen'        | => 'pg_pggen'             | 一般公開可否               |
|'pg_pgu18'        | => 'pg_pgu18'             | 未成年参加可否             |
|'pg_badprog'      | => 'pg_badprog'           | 重なると困る企画           |
|'pg_enquete'      | => 'pg_enquete'           | 企画経験                   |
|'fc_comment'      | => 'fc_comment'           | 備考(連絡可能時間帯)       |
+------------------+---------------------------+----------------------------+
|'wbd' 'mon'       | => equips[]               | 要望提供機材               |
|'dvd' 'syo'       |        {                  |                            |
|'fc_other_naiyou' |            'name'         |    機材名                  |
|'fc_mochikomi'    |        }                  |                            |
+------------------+---------------------------+----------------------------+
|                  | => equips[]               | 要望提供機材               |
|                  |        {                  |                            |
|'mic' 'mic2'      |            'name'         |    機材名                  |
|'miccnt' 'miccnt2'|            'count'        |    本数                    |
|                  |        }                  |                            |
+------------------+---------------------------+----------------------------+
|                  | => equips[]               | 要望提供機材               |
|                  |        {                  |                            |
|'fc_vid'          |            'name'         |    機材名                  |
|'av-v'            |            'vif'          |    映像接続(その他内容)    |
|'av-a'            |            'aif'          |    音声接続(その他内容)    |
|                  |        }                  |                            |
+------------------+---------------------------+----------------------------+
|                  | => equips[]               | 要望提供機材               |
|                  |        {                  |                            |
|'fc_pc'           |            'name'         |    機材名                  |
|'pc-v'            |            'vif'          |    映像接続(その他内容)    |
|'pc-a'            |            'aif'          |    音声接続(その他内容)    |
|'lan'             |            'eif'          |    LAN接続(その他内容)     |
|'lanreason'       |            'intende'      |    LAN利用目的             |
|                  |        }                  |                            |
+------------------+---------------------------+----------------------------+
|                  | => casts[]                | 出演者情報                 |
|                  |        {                  |                            |
|*'p1_name'        |            'name'         | 出演者登録名               |
|'reg_num'         |            'entrantregno' | 出演者登録番号             |
|'py_name'         |            'pgname'       | 企画ネーム                 |
|'py_name_f'       |            'pgnamef'      | 企画ネームフリガナ         |
|'py_title'        |            'pgtitle'      | 肩書                       |
|                  |            'needreq'      | 出演交渉(固定値)           |
|                  |            'needguest'    | ゲスト申請(固定値)         |
|                  |        }                  |                            |
+------------------+---------------------------+----------------------------+
|                  | => casts[]                | 出演者情報                 |
|                  |        {                  |                            |
|'pp<n>_name'      |            'pgname'       | 企画ネーム                 |
|'pp<n>_name_f'    |            'pgnamef'      | 企画ネームフリガナ         |
|'pp<n>_title'     |            'pgtitle'      | 肩書                       |
|'pp<n>_con'       |            'needreq'      | 出演交渉                   |
|'pp<n>_grq'       |            'needguest'    | ゲスト申請                 |
|                  |        }                  |                            |
+------------------+---------------------------+----------------------------+

WebAPI JSONキーとDataBase登録先との関係表
====

注: prog_no はクライアントからではなく、PgRegProgram登録時にAutoIndentして得る
+------------------------+-----------------------+
|  JSONキー              | schema                |
|                        | => column             |
+------------------------+-----------------------+
|                        | PgRegProgram          |
| 'prog_no'              | => regpgid(AutoIndent)|
| 'regdate'              | => regdate            | 
| 'p1_name'              | => regname            | 
| 'email'                | => regma              | 
| 'reg_num'              | => regno              | 
| 'tel'                  | => telno              | 
| 'fax'                  | => faxno              | 
| 'cellphone'            | => celno              | 
| 'pg_name'              | => name               | 
| 'pg_name_f'            | => namef              | 
| 'pg_kind'              | => type               | 
| 'pg_place'             | => place              |
| 'pg_layout'            | => layout             |
| 'pg_time'              | => date               |
| 'pg_koma'              | => classlen           |
| 'pg_ninzu'             | => expmaxcnt          | 
| 'pg_naiyou'            | => content            | 
| 'pg_naiyou_k'          | => contentpub         | 
| 'pg_kiroku_kb'         | => realpub            | 
| 'pg_kiroku_ka'         | => afterpub           | 
| 'pg_pggen'             | => openpg             | 
| 'pg_pgu18'             | => restpg             | 
| 'pg_badprog'           | => avoiddup           | 
| 'pg_enquete'           | => experience         | 
| 'fc_comment'           | => comment            | 
+------------------------+-----------------------+
|                        | PgRegEquip            |
| 'equips[].prog_no'     | => regpgid            |
| 'equips[].name'        | => name               |
| 'equips[].count'       | => count              |
| 'equips[].vif'         | => vif                |
| 'equips[].aif'         | => aif                |
| 'equips[].eif'         | => eif                |
| 'equips[].intende'     | => intende            |
+------------------------+-----------------------+
|                        | PgRegCast             |
| 'casts[].name'         |                       | 
| 'casts[].entrantregno' | => entrantregno       | 
| 'casts[].pgname'       | => name               | 
| 'casts[].pgnamef'      | => namef              | 
| 'casts[].pgtitle'      | => title              | 
| 'casts[].needreq'      | => needreq            | 
| 'casts[].needguest'    | => needguest          | 
+------------------------+-----------------------+
|                        | PgAllCast             |
| 'casts[].name'         | => name               | 
| 'casts[].entrantregno' | => regno              | 
+------------------------+-----------------------+
|                        | PgAllCast             |
| 'casts[].pgname'       | => name               | 
| 'casts[].pgnamef'      | => namef              | 
+------------------------+-----------------------+


*参考* Ver.0 API
======
(ConkanProgram V1.0.0以前のWebAPI)

V1.0.0以前では、深度1のオブジェクトJSONしか使っていない

JSONキー 'WebAPI_VERSION' が存在しない場合Ver.0 とみなす

+------------------+--------------------------------+-----------------------+
|Param名           | =>  JSONキー                   | schema                |
|                  |                                | =>  column            |
+------------------+--------------------------------+-----------------------+
|                  |                                | PgRegProgram          |
|'prog_no'         | => '企画ID'                    | => regpgid            |
|'regdate'         | => '申し込み日付'              | => regdate            |
|'p1_name'         | => '申込者名'                  | => regname            |
|'email'           | => 'メールアドレス'            | => regma              |
|'reg_num'         | => '参加番号'                  | => regno              |
|'tel'             | => '電話番号'                  | => telno              |
|'fax'             | => 'FAX番号'                   | => faxno              |
|'cellphone'       | => '携帯番号'                  | => celno              |
|'pg_name'         | => '企画名'                    | => name               |
|'pg_name_f'       | => '企画名フリガナ'            | => namef              |
|'pg_kind'         | => '企画種別'                  | => type               |
|'pg_kind2'        | => '企画種別その他内容'        |    ++++               |
|'pg_place'        | => '希望場所'                  | => place              |
|'pg_place2'       | => '希望場所その他内容'        |    +++++              |
|'pg_layout'       | => '希望レイアウト'            | => layout             |
|'pg_layout2'      | => '希望レイアウトその他内容'  |    ++++++             |
|'pg_time'         | => '希望時刻'                  | => date               |
|'pg_time2'        | => '希望時刻その他内容'        |    ++++               |
|'pg_koma'         | => '希望コマ数'                | => classlen           |
|'pg_koma2'        | => '希望コマ数その他内容'      |    ++++++++           |
|'pg_ninzu'        | => '予想人数'                  | => expmaxcnt          |
|'pg_naiyou'       | => '企画内容'                  | => content            |
|'pg_naiyou_k'     | => '内容事前公開'              | => contentpub         |
|'pg_kiroku_kb'    | => 'リアルタイム公開'          | => realpub            |
|'pg_kiroku_ka'    | => '事後公開'                  | => afterpub           |
|'pg_pggen'        | => '一般公開可否'              | => openpg             |
|'pg_pgu18'        | => '未成年参加可否'            | => restpg             |
|'pg_badprog'      | => '重なると困る企画'          | => avoiddup           |
|'pg_enquete'      | => '企画経験'                  | => experience         |
|'fc_comment'      | => '備考'                      | => comment            |
|'phonetime'       |                                |    +++++++            |
+------------------+--------------------------------+-----------------------+
|                  |                                | PgRegEquip            |
|*'prog_no'        | => *'企画ID'                   | => regpgid            |
|'wbd'             | => 'ホワイトボード'            | => name               |
+------------------+--------------------------------+-----------------------+
|                  |                                | PgRegEquip            |
|*'prog_no'        | => *'企画ID'                   | => regpgid            |
|'mic'             | => '壇上マイク'                | => name               |
|'miccnt'          | => '壇上マイク本数'            | => count              |
+------------------+--------------------------------+-----------------------+
|                  |                                | PgRegEquip            |
|*'prog_no'        | => *'企画ID'                   | => regpgid            |
|'mic2'            | => '客席マイク'                | => name               |
|'mic2cnt'         | => '客席マイク本数'            | => count              |
+------------------+--------------------------------+-----------------------+
|                  |                                | PgRegEquip            |
|*'prog_no'        | => *'企画ID'                   | => regpgid            |
|'mon'             | => 'モニタ/スクリーン'         | => name               |
+------------------+--------------------------------+-----------------------+
|                  |                                | PgRegEquip            |
|*'prog_no'        | => *'企画ID'                   | => regpgid            |
|'dvd'             | => 'BD/DVDプレイヤー'          | => name               |
+------------------+--------------------------------+-----------------------+
|                  |                                | PgRegEquip            |
|*'prog_no'        | => *'企画ID'                   | => regpgid            |
|'syo'             | => '書画カメラ'                | => name               |
+------------------+--------------------------------+-----------------------+
|                  |                                | PgRegEquip            |
|*'prog_no'        | => *'企画ID'                   | => regpgid            |
|'fc_other_naiyou' | => 'その他要望機材'            | => name               |
+------------------+--------------------------------+-----------------------+
|                  |                                | PgRegEquip            |
|*'prog_no'        | => *'企画ID'                   | => regpgid            |
|'fc_vid'          | => '持ち込み映像機器'          | => name               |
|'av-v'            | => '映像機器映像接続'          | => vif                |
|'av-v_velse'      | => '映像機器映像接続その他内容'|    +++                |
|'av-a'            | => '映像機器音声接続'          | => aif                |
|'av-a_velse'      | => '映像機器音声接続その他内容'|    +++                |
+------------------+--------------------------------+-----------------------+
|                  |                                | PgRegEquip            |
|*'prog_no'        | => *'企画ID'                   | => regpgid            |
|'fc_pc'           | => '持ち込みPC'                | => name               |
|'pc-v'            | => 'PC映像接続'                | => vif                |
|'pc-v_velse'      | => 'PC映像接続その他内容'      |    +++                |
|'pc-a'            | => 'PC音声接続'                | => aif                |
|'pc-a_velse'      | => 'PC音声接続その他内容'      |    +++                |
|'lan'             | => 'PC-LAN接続'                | => eif                |
|'pc-l_velse'      | => 'PC-LAN接続その他内容'      |    +++                |
|'lanreason'       | => 'LAN利用目的'               | => intende            |
+------------------+--------------------------------+-----------------------+
|                  |                                | PgRegEquip            |
|*'prog_no'        | => *'企画ID'                   | => regpgid            |
|'fc_mochikomi'    | => 'その他持ち込み機材'        | => name               |
+------------------+--------------------------------+-----------------------+
|                  |                                | PgRegCast             |
|*'prog_no'        | => *'企画ID'                   | => regpgid            |
|'youdo'           | => '申込者出演'                |                       |
|*'p1_name'        | => *'申込者名'                 |                       |
|*'reg_num'        | => *'参加番号'                 | => entrantregno       |
|'py_name'         | => '出演者氏名1'               | => name               |
|'py_name_f'       | => '出演者氏名ふりがな1'       | => namef              |
|'py_title'        | => '出演者肩書1'               | => title              |
|                  | => '出演交渉1'                 | => needreq            |
|                  | => 'ゲスト申請1'               | => needguest          |
+------------------+--------------------------------+-----------------------+
|                  |                                | PgRegCast             |
|*'prog_no'        | => *'企画ID'                   | => regpgid            |
|'pp<n>_name'      | => '出演者氏名<n>'             | => name               |
|'pp<n>_name_f'    | => '出演者氏名ふりがな<n>'     | => namef              |
|'pp<n>_title'     | => '出演者肩書<n>'             | => title              |
|'pp<n>_con'       | => '出演交渉<n>'               | => needreq            |
|'pp<n>_grq'       | => 'ゲスト申請<n>'             | => needguest          |
+------------------+--------------------------------+-----------------------+