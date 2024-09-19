import psutil
import os
import time

FREE_RATIO = 0.05
PROCESS_WHITELIST = []

def do_oom_kill():
    own_pid = os.getpid()
    own_username = None

    print('do_oom_kill() called')

    processes = []
    for p in psutil.process_iter():
        try:
            tmp = {}
            tmp['pid'] = p.pid
            tmp['name'] = p.name()
            tmp['username'] = p.username() # this might cause an AccessDenied exception
            tmp['memory_rss'] = p.memory_info().rss
            tmp['consider'] = (tmp['name'] not in PROCESS_WHITELIST)
            processes.append(tmp)
        except:
            continue

    # find out the user running this script
    for p in processes:
        if p['pid'] == own_pid:
            own_username = p['username']
            break

    # filter the processes for the ones that is being run by the same user as the script, if detected
    if own_username:
        processes = filter(lambda a: a['username'] == own_username, processes)

    processes = sorted(processes, key = lambda a: a['memory_rss'], reverse=True)

    print('All processes:')
    for p in processes:
        print(' ', p)

    for p in processes:
        if not p['consider']:
            continue
        
        print('Killing process with pid', p['pid'])
        print(' ', p)

        p2 = psutil.Process(p['pid'])
        p2.kill()

        break

    print('WARNING: No process found to kill.')

def oom_check_loop():
    print('Starting free memory monitoring with trigger at %.2f%%...' % (FREE_RATIO * 100))

    while True:
        memory_info = psutil.virtual_memory()

        if memory_info.available < memory_info.total * FREE_RATIO:
            print('Low memory detected:')
            print(' ', memory_info)
            do_oom_kill()
            print('')
        
        time.sleep(5.0)

if __name__ == '__main__':
    oom_check_loop()
