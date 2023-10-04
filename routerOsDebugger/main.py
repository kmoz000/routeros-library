import click
import ros_api

@click.command()
@click.option('-a', default="192.168.1.1", help='address; default <192.168.1.1>', type=click.STRING)
@click.option('-u', default="admin", help='username; default <admin>', type=click.STRING)
@click.option('-p', default="", help='password; default <empty>', type=click.STRING)
@click.argument('script', nargs=1, required=True, type=click.Path(exists=True))
def debug_script(a, u, p, script):
    """Router Os Simple Script Debugger"""
    try:
        scriptcontent = open(script).readlines()
        router = ros_api.Api(address=a, user=u, password=p)
        r = router.talk('/system/script/print')
        scripts_list = [s["name"] for s in r]
        if 'debug_script' in scripts_list:
            click.echo(click.style([s["name"] for s in r], fg='green'),color=True)
        else:
            try:
                res = router.talk((":put =heelo"))
                click.echo(click.style('results: {}'.format(res), fg='red'),color=True)
            except Exception as ex:
                click.echo(click.style('Exception: {}'.format(ex), fg='red'),color=True)
            
            # for line in scriptcontent:
            #     if line[0] != "#":
            #         try:
            #             res = router.talk(line.replace(" ", " ="))
            #             click.echo(click.style('results: {}'.format(res), fg='red'),color=True)
            #         except Exception as ex:
            #             click.echo(click.style('Exception: {}'.format(ex), fg='red'),color=True)
    except Exception as ex:
        click.echo(color=True)
if __name__ == '__main__':
    debug_script()
