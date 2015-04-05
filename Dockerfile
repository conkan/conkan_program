# source is CentOS6
FROM centos:centos6

MAINTAINER Studio-REM <rem@s-rem.jp>

#----------------------------------------------------------
# 基本設定
#----------------------------------------------------------
RUN yum -y install https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN yum -y install witch curl git htop man vim sudo unzip wget tar less
RUN yum -y install perl-CPAN
RUN yum -y update
RUN curl -L http://cpanmin.us | perl - -- App::cpanminus

# ホスト名を設定
ENV HOSTNAME conkan

# shell環境等設定
ADD doccnf/bashrc /root/.bashrc
ADD doccnf/vimrc /root/.vimrc
ADD doccnf/clock /etc/sysconfig/clock
ADD doccnf/i18n /etc/sysconfig/i18n
RUN rm -f /etc/localtime
RUN ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
ENV HOME /root
ENV TERM xterm
WORKDIR /root

#----------------------------------------------------------
# 対象インストール
#----------------------------------------------------------
# nginx
RUN yum install -y nginx

# mysql-client
RUN yum -y install mysql
RUN yum -y install mysql-devel
#
# gcc
RUN yum -y install gcc
RUN yum -y install patch

# Starman
RUN cpanm -i Starman

# daemontools
RUN mkdir -p /package;chmod 1755 /package;cd /package;wget http://cr.yp.to/daemontools/daemontools-0.76.tar.gz;tar xvzf daemontools-0.76.tar.gz;cd admin/daemontools-0.76;wget http://www.qmail.org/moni.csi.hu/pub/glibc-2.3.1/daemontools-0.76.errno.patch;patch -p1 < daemontools-0.76.errno.patch;package/install

# Install Perl Module (Catalyst)
RUN cpanm -i YAML
RUN cpanm -i DBI
RUN cpanm -in DBD::mysql
RUN cpanm -i DBIx::Class
RUN cpanm -i DBIx::Class::Cursor::Cached
RUN cpanm -i Email::MIME
RUN cpanm -i DateTime::Format::MySQL
RUN cpanm -i CGI
RUN cpanm -in FormValidator::Simple::Plugin::Japanese
RUN cpanm -i HTTP::Server::Simple
RUN cpanm -i Moose
RUN cpanm -in MooseX::Daemonize
RUN cpanm -i Catalyst::Runtime
RUN cpanm -in Test::Expect
RUN cpanm -in CatalystX::REPL
RUN cpanm -i Task::Catalyst
RUN cpanm -i Catalyst::Devel
RUN cpanm -i Catalyst::Engine::Apache
RUN cpanm -i Catalyst::View::TT
RUN cpanm -i Catalyst::View::TT::ForceUTF8
RUN cpanm -i Catalyst::View::JSON
RUN cpanm -i Catalyst::Model::DBI
RUN cpanm -i Catalyst::Model::DBIC::Schema
RUN cpanm -i Catalyst::Model::Adaptor
RUN cpanm -i Catalyst::Helper::Model::Email
RUN cpanm -i Catalyst::Plugin::FormValidator
RUN cpanm -i Catalyst::Plugin::ConfigLoader
RUN cpanm -i Catalyst::Plugin::Static::Simple
RUN cpanm -i Catalyst::Plugin::AutoRestart
RUN cpanm -i Catalyst::Plugin::Session
RUN cpanm -i Catalyst::Plugin::Session::FastMmap
RUN cpanm -i Catalyst::Plugin::Session::Store::FastMmap
RUN cpanm -i Catalyst::Plugin::Session::State::Cookie
RUN cpanm -i Catalyst::Plugin::Authentication
RUN cpanm -i Catalyst::Plugin::Authorization::Roles
RUN cpanm -i Catalyst::Plugin::FormValidator::Simple
RUN cpanm -i Catalyst::Plugin::FormValidator::Simple::Auto
RUN cpanm -i Catalyst::Plugin::FillInForm
RUN cpanm -i Catalyst::Plugin::I18N

# cpanm work削除
RUN rm -rf .cpanm/*

#nginx設定
ADD doccnf/nginx.conf /etc/nginx/nginx.conf

# daemontools設定
RUN mkdir -p /service/conkan
ADD doccnf/conkan_run /service/conkan/run
RUN chmod 755 /service/conkan/run
RUN mkdir -p /service/nginx
ADD doccnf/nginx_run /service/nginx/run
RUN chmod 755 /service/nginx/run

#----------------------------------------------------------
# 起動
#----------------------------------------------------------
EXPOSE 80 443
CMD [ "/usr/local/bin/svscanboot" ]
