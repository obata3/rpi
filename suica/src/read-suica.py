#!/usr/bin/env python

import os
import sys
import binascii
import logging
import nfc

def connected(tag):
  print >> sys.stderr, tag

  if isinstance(tag, nfc.tag.tt3.Type3Tag):
    try:
      for i in range(20):
        print "%s" % binascii.hexlify(tag.read([i], 0x090f))
        sys.stdout.flush()
    except Exception as e:
      print "error: %s" % e
  else:
    print "error: tag isn't Type3Tag"
  sys.stdout.close()
  os.close(1)
  return True

clf = nfc.ContactlessFrontend('usb')
clf.connect(rdwr={'on-connect': connected})
