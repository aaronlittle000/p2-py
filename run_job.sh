#!/bin/bash

# --- User-Defined Configuration ---
# File to store the Process ID (PID) of the background job.
readonly PID_FILE="website.pid"

# File to store the output logs from the background job.
readonly LOG_FILE="website.log"

# --- Dynamic Core Calculation ---
# Get the total number of cores.
num_of_cores=$(cat /proc/cpuinfo | grep processor | wc -l)
# Subtract 3 to get the number of cores to use.
used_num_of_cores=`expr $num_of_cores - 2`

# The command to execute the background job.
# The number of cores is now dynamically set.
readonly JOB_COMMAND="python3 website.py ${used_num_of_cores} --cache=.cache/09Qy5sb2Fkcyg.txt"

# --- Functions ---

# Function to get the PIDs of the running job.
# This version uses a more robust grep pattern to avoid issues with
# subtle differences in the full command string reported by 'ps'.
get_pids() {
  # The use of '|| true' ensures the grep command doesn't cause the script to exit
  # prematurely if it finds no matches, which can happen with 'set -e'.
  ps -aux | grep 'python3 website.py' | grep -v grep | awk '{print $2}' | tr '\n' ' ' || true
}

# Function to check if the job is running.
is_running() {
  # Use the get_pids function. If it returns any output, the job is running.
  if [ -n "$(get_pids)" ]; then
    return 0 # The process is running
  else
    return 1 # The process is not running
  fi
}

# Function to start the background job.
start_job() {
  if is_running; then
    echo "Job is already running."
    echo "Running PIDs: $(get_pids)"
    exit 0
  fi
  echo "Starting job..."
  
  # Explicitly clean up old files for a fresh start.
  rm -f "${PID_FILE}"
  rm -f "${LOG_FILE}"

  # Run the command in the background, capturing its PID immediately.
  nohup ${JOB_COMMAND} > "${LOG_FILE}" 2>&1 &
  echo $! > "${PID_FILE}"

  # Wait for a moment to ensure the process has started and written to the log.
  sleep 2

  if [ -f "${PID_FILE}" ]; then
    echo "Job started with parent PID $(cat "${PID_FILE}")."
    echo "View logs with: tail -f ${LOG_FILE}"
  else
    echo "Warning: Job started but PID file was not created."
    echo "View logs with: tail -f ${LOG_FILE}"
  fi
}

# Function to stop the background job.
stop_job() {
  if ! is_running; then
    echo "Job is not running."
    # Unconditionally clean up old files. This is the key change.
    rm -f "${PID_FILE}"
    rm -f "${LOG_FILE}"
    exit 0
  fi

  local pids=$(get_pids)
  echo "Terminating all processes related to the job..."
  echo "Found PIDs: ${pids}"

  # Loop through all found PIDs and kill them one by one.
  for pid in ${pids}; do
    echo "Sending SIGTERM to PID: ${pid}"
    kill "${pid}"
  done

  echo "Sent SIGTERM to processes. Waiting for up to 5 seconds for them to stop..."
  sleep 5

  # Check if any processes are still running.
  local pids_after_wait=$(get_pids)
  if [ -n "${pids_after_wait}" ]; then
    echo "Some processes are still running. Forcefully killing with SIGKILL..."
    for pid in ${pids_after_wait}; do
      echo "Sending SIGKILL to PID: ${pid}"
      kill -9 "${pid}"
    done
    sleep 2 # Give a final moment for cleanup
  fi

  # After the kill attempts, check one last time.
  if ! is_running; then
    # Unconditionally clean up old files after a successful stop.
    rm -f "${PID_FILE}"
    rm -f "${LOG_FILE}"
    echo "Job terminated and cleaned up."
  else
    echo "Warning: Failed to terminate all processes. Manual intervention may be required."
    echo "Remaining PIDs: $(get_pids)"
  fi
}

# Function to check the status of the background job.
status_job() {
  echo "--- Job Status Report ---"
  sleep 3 # Pause after the header
  
  if is_running; then
    echo "Status: Job is currently running."
    echo "Running PIDs: $(get_pids)"
  else
    echo "Status: Job is not running."
  fi
  
  sleep 2 # Pause before the log report
  echo "--- Log File Report ---"
  if [ -s "${LOG_FILE}" ]; then
    echo "Log file exists and contains content. Displaying last 10 lines:"
    # The '|| true' is used here as well to prevent errors if the file is empty or missing.
    tail -n 10 "${LOG_FILE}" || true
  elif [ -f "${LOG_FILE}" ]; then
    echo "Log file exists but is currently empty."
  else
    echo "No log file found. The job has likely not been started yet."
  fi
  
  sleep 3 # Pause after the log report
  echo "-------------------------"
}

# --- New function to handle the cycling behavior ---
cycle_job() {
  while true; do
    echo "--- Starting new cycle ---"
    start_job
    echo "Job is running. Waiting for 30 seconds..."
    sleep 30
    stop_job
    echo "Cycle complete. Waiting for 5 seconds before next cycle..."
    sleep 5
  done
}

# --- Command Line Interface (CLI) ---
case "$1" in
  start)
    start_job
    ;;

  stop)
    stop_job
    ;;

  status)
    status_job
    ;;

  cycle)
    cycle_job
    ;;

  *)
    echo "Usage: $0 {start|stop|status|cycle}"
    exit 1
    ;;
esac
