#!/bin/bash

must_quit=0
if [ $# -eq 0 ] || [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "help" ]; then   
    echo "Syntax:  $0 --start|--version <version id>"
    echo "   e.g.  $0 --version v1-alpha"
    echo ""
    must_quit=1
fi

if [ $must_quit -eq 0 ]; then
  if [ "$1" == "--start" ] || [ "$1" == "-s" ]; then
    action="-k subscription"
  elif [ "$1" == "--version" ] || [ "$1" == "-v" ]; then
    if [ -z $2 ]; then
      echo "  ERROR: A version must be specified when using argument '-v'";
      must_quit=1
    else
      if [ -f subscription/subscription-$2.yaml ]; then
        action="-f subscription/subscription-$2.yaml"
      else
        echo "ERROR: Invalid version! The available versions are:"
        ls subscription/subscription-* | cut -d '/' -f 2 | cut -d '.' -f 1 | cut -d '-' -f 2,3
        must_quit=1
      fi
    fi
  elif [ "$1" == "--remove" ] || [ "$1" == "-r" ]; then
    oc delete -k subscription && oc delete subscription --all -n acm-demo
    ansible-playbook ansible-hook/setup/main.yml
    must_quit=1
  else
    echo "Invalid option";
  fi
fi

if [ $must_quit -eq 0 ]; then
  oc apply $action
fi
