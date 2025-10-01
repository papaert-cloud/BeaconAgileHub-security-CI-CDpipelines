from remediate import handler

def test_handler_no_event():
    event = {}
    result = handler(event, None)
    assert result['status'] == 'ok'
