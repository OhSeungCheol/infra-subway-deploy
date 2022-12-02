#!/bin/bash
echo ""
echo "Hello Bash!"

## 변수 설정

PROJECT_PATH=/home/ubuntu/myapp/infra-subway-deploy
SERVICE_PATH=$PROJECT_PATH/build/libs
LOG_PATH=$PROJECT_PATH/logs
SERVICE_NAME=subway-0.0.1-SNAPSHOT.jar
LOG_FILE_NAME=mylog.log
PARAMETER_COUNT=2
PROFILES=("test" "prod" "local")

SERVICE_BRANCH=$1
STAGE=$2

function check_parameter_validation() {
        # 파라미터 개수 검증
        if [[ $1 -ne $PARAMETER_COUNT ]]
        then
                echo "Need 2 Parameter: Branch, Profile"
                exit 1
        fi

        # fetch 명령어 질의의 결과 성공 여부로 브랜치 파라미터의 유효성을 판단
        cd $PROJECT_PATH
        git fetch origin $2 > /dev/null 2>&1
        if [[ $? -ne 0 ]]
        then
                echo "Branch is wrong"
                exit 1
        fi

        # 초기 선언 한 PROFILES 에 포함되어 있는지 여부로 프로필 파라미터의 유효성을 판단
        IS_COLLECT=0
        for profile in ${PROFILES[@]}
        do
                if [[ $profile == $STAGE ]]
                then
                        IS_COLLECT=1
                        break
                fi
        done
        if [[ $IS_COLLECT -eq 0 ]]
        then
                echo "Profile is wrong"
                exit 1
        fi
}

function pull() {
        echo -e ">> [pull] pull Request"
        git pull origin $SERVICE_BRANCH
}

function check_df() {
        echo "[check_ef] check update"
        cd $PROJECT_PATH
        git fetch
        master=$(git rev-parse $SERVICE_BRANCH)
        remote=$(git rev-parse origin/$SERVICE_BRANCH)

        if [[ $master == $remote ]]; then
                echo -e "[$(date)] Nothing to do!!! 😫"
                exit 1
        fi
        echo -e "[check_ef] find new revision:$remote"
}

function build() {
        echo "[build] start build"
        cd $PROJECT_PATH
        ./gradlew clean build
        echo "[build] end build"
}

function kill_app(){
        exec_result=$(ps -ef | grep ${SERVICE_NAME})
        echo [kill_app] find kill proccess info : $exec_result
        pid=$(echo ${exec_result} | cut -d " " -f2)
        echo "[kill_app] kill $pid"
        kill -9 $pid
}

function run_app(){
        cd $SERVICE_PATH
        nohup java -jar -Dspring.profiles.active=$STAGE $SERVICE_NAME 1> $LOG_PATH/$LOG_FILE_NAME 2>&1 &
        echo "[run_app] success run proccess"
}

now=$(date)
echo -e "======================================="
echo -e "           << 스크립트 >>"
echo -e "    $now"
echo -e "======================================="

## check validation
check_parameter_validation $# $SERVICE_BRANCH $STAGE

## 저장소 pull
echo ""
echo "===1==="
check_df
pull
echo "===1==="

## gradle build
echo ""
echo "===2==="
build
echo "===2==="

## 프로세스 pid를 찾는 명령어
## 프로세스를 종료하는 명령어
echo ""
echo "===3==="
kill_app
echo "===3==="

## 시작 명령어
echo ""
echo "===4==="
run_app
echo "===4==="